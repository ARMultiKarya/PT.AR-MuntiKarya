<?php
/**
 * PT AR MULTI KARYA - MySQL REST API Gateway (PHP Version)
 * Deskripsi: Gateway API untuk menghubungkan frontend index.html dengan database MySQL / MariaDB.
 */

// Enable CORS
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit(0);
}

// === DATABASE CONFIGURATION ===
$db_host = 'localhost';
$db_name = 'pt_ar_multikarya_db';
$db_user = 'root';
$db_pass = '';

try {
    $pdo = new PDO("mysql:host=$db_host;dbname=$db_name;charset=utf8mb4", $db_user, $db_pass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8mb4"
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["error" => "Database connection failed: " . $e->getMessage()]);
    exit;
}

$method = $_SERVER['REQUEST_METHOD'];
$store = $_GET['store'] ?? '';

if (!$store) {
    http_response_code(400);
    echo json_encode(["error" => "Store parameter is required"]);
    exit;
}

// Helper to convert chat_messages readBy text array format
function parseReadBy($readByStr) {
    if (empty($readByStr)) return [];
    // If it's a JSON array string
    if (strpos($readByStr, '[') === 0) {
        return json_decode($readByStr, true) ?: [];
    }
    // If it's a comma-separated list
    return explode(',', $readByStr);
}

// HELPER ROUTING
if ($method === 'GET') {
    if (isset($_GET['id'])) {
        $stmt = $pdo->prepare("SELECT * FROM `$store` WHERE id = ?");
        $stmt->execute([$_GET['id']]);
        $row = $stmt->fetch();
        if ($row) {
            if ($store === 'chat_messages' && isset($row['readBy'])) {
                $row['readBy'] = parseReadBy($row['readBy']);
            }
            // Merge relational items
            if ($store === 'po') {
                $itemStmt = $pdo->prepare("SELECT * FROM po_items WHERE poId = ?");
                $itemStmt->execute([$row['id']]);
                $row['items'] = $itemStmt->fetchAll();
            } else if ($store === 'bukti_pembelian') {
                $itemStmt = $pdo->prepare("SELECT * FROM bukti_pembelian_items WHERE buktiPembelianId = ?");
                $itemStmt->execute([$row['id']]);
                $row['items'] = array_map(function($it) {
                    return [
                        "barangId" => (int)$it["barangId"],
                        "qty" => (float)$it["qty"],
                        "unitCost" => (float)$it["unitCost"]
                    ];
                }, $itemStmt->fetchAll());
            } else if ($store === 'invoice_jual') {
                $itemStmt = $pdo->prepare("SELECT * FROM invoice_jual_items WHERE invoiceJualId = ?");
                $itemStmt->execute([$row['id']]);
                $row['items'] = $itemStmt->fetchAll();
            }
        }
        echo json_encode($row ?: null);
    } else {
        $stmt = $pdo->query("SELECT * FROM `$store`");
        $rows = $stmt->fetchAll();
        
        if ($store === 'chat_messages') {
            foreach ($rows as &$row) {
                if (isset($row['readBy'])) {
                    $row['readBy'] = parseReadBy($row['readBy']);
                }
            }
        } else if ($store === 'po') {
            $itemStmt = $pdo->query("SELECT * FROM po_items");
            $allItems = $itemStmt->fetchAll();
            foreach ($rows as &$row) {
                $row['items'] = array_values(array_filter($allItems, function($it) use ($row) {
                    return $it['poId'] == $row['id'];
                }));
            }
        } else if ($store === 'bukti_pembelian') {
            $itemStmt = $pdo->query("SELECT * FROM bukti_pembelian_items");
            $allItems = $itemStmt->fetchAll();
            foreach ($rows as &$row) {
                $row['items'] = array_map(function($it) {
                    return [
                        "barangId" => (int)$it["barangId"],
                        "qty" => (float)$it["qty"],
                        "unitCost" => (float)$it["unitCost"]
                    ];
                }, array_values(array_filter($allItems, function($it) use ($row) {
                    return $it['buktiPembelianId'] == $row['id'];
                })));
            }
        } else if ($store === 'invoice_jual') {
            $itemStmt = $pdo->query("SELECT * FROM invoice_jual_items");
            $allItems = $itemStmt->fetchAll();
            foreach ($rows as &$row) {
                $row['items'] = array_values(array_filter($allItems, function($it) use ($row) {
                    return $it['invoiceJualId'] == $row['id'];
                }));
            }
        }
        echo json_encode($rows);
    }
} 
else if ($method === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);
    if (!$input) {
        http_response_code(400);
        echo json_encode(["error" => "Invalid JSON input"]);
        exit;
    }
    
    $items = $input['items'] ?? null;
    unset($input['items']);
    
    // Special handling for chat_messages readBy array -> stringify for MySQL
    if ($store === 'chat_messages' && isset($input['readBy']) && is_array($input['readBy'])) {
        $input['readBy'] = json_encode($input['readBy']);
    }
    
    $id = $input['id'] ?? null;
    
    if ($id && $store !== 'settings') {
        // UPDATE
        $fields = [];
        $values = [];
        foreach ($input as $k => $v) {
            if ($k === 'id') continue;
            $fields[] = "`$k` = ?";
            $values[] = $v;
        }
        $values[] = $id;
        $sql = "UPDATE `$store` SET " . implode(", ", $fields) . " WHERE id = ?";
        $stmt = $pdo->prepare($sql);
        $stmt->execute($values);
        $finalId = $id;
    } else {
        // INSERT
        if ($store === 'settings') {
            // Delete old settings first to simulate upsert
            $pdo->prepare("DELETE FROM settings WHERE id = ?")->execute([$input['id']]);
        }
        
        $fields = array_keys($input);
        $placeholders = array_fill(0, count($fields), "?");
        $values = array_values($input);
        
        $sql = "INSERT INTO `$store` (" . implode(", ", array_map(function($f) { return "`$f`"; }, $fields)) . ") VALUES (" . implode(", ", $placeholders) . ")";
        $stmt = $pdo->prepare($sql);
        $stmt->execute($values);
        $finalId = $store === 'settings' ? $input['id'] : $pdo->lastInsertId();
    }
    
    // Update nested items
    if ($store === 'po' && $items !== null) {
        $pdo->prepare("DELETE FROM po_items WHERE poId = ?")->execute([$finalId]);
        foreach ($items as $it) {
            $stmt = $pdo->prepare("INSERT INTO po_items (poId, barangId, qty, price, total) VALUES (?, ?, ?, ?, ?)");
            $stmt->execute([$finalId, (int)$it['barangId'], (float)$it['qty'], (float)$it['price'], (float)$it['total']]);
        }
    } else if ($store === 'bukti_pembelian' && $items !== null) {
        $pdo->prepare("DELETE FROM bukti_pembelian_items WHERE buktiPembelianId = ?")->execute([$finalId]);
        foreach ($items as $it) {
            $stmt = $pdo->prepare("INSERT INTO bukti_pembelian_items (buktiPembelianId, barangId, qty, unitCost) VALUES (?, ?, ?, ?)");
            $stmt->execute([$finalId, (int)$it['barangId'], (float)$it['qty'], (float)$it['unitCost']]);
        }
    } else if ($store === 'invoice_jual' && $items !== null) {
        $pdo->prepare("DELETE FROM invoice_jual_items WHERE invoiceJualId = ?")->execute([$finalId]);
        foreach ($items as $it) {
            $stmt = $pdo->prepare("INSERT INTO invoice_jual_items (invoiceJualId, barangId, qty, price, total, hpp) VALUES (?, ?, ?, ?, ?, ?)");
            $stmt->execute([$finalId, (int)$it['barangId'], (float)$it['qty'], (float)$it['price'], (float)$it['total'], (float)($it['hpp'] ?? 0)]);
        }
    }
    
    echo json_encode(["success" => true, "id" => $finalId]);
} 
else if ($method === 'DELETE') {
    $id = $_GET['id'] ?? '';
    if (!$id) {
        http_response_code(400);
        echo json_encode(["error" => "ID parameter is required"]);
        exit;
    }
    
    // Cascading deletes on item tables
    if ($store === 'po') {
        $pdo->prepare("DELETE FROM po_items WHERE poId = ?")->execute([$id]);
    } else if ($store === 'bukti_pembelian') {
        $pdo->prepare("DELETE FROM bukti_pembelian_items WHERE buktiPembelianId = ?")->execute([$id]);
    } else if ($store === 'invoice_jual') {
        $pdo->prepare("DELETE FROM invoice_jual_items WHERE invoiceJualId = ?")->execute([$id]);
    }
    
    $stmt = $pdo->prepare("DELETE FROM `$store` WHERE id = ?");
    $stmt->execute([$id]);
    
    echo json_encode(["success" => true]);
}
else {
    http_response_code(405);
    echo json_encode(["error" => "Method not allowed"]);
}
