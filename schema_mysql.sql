-- =========================================================
-- DATABASE SCHEMA MYSQL / MARIADB (XAMPP / CPanel / VPS)
-- PT AR MULTI KARYA BOROBUDUR
-- =========================================================

CREATE DATABASE IF NOT EXISTS `pt_ar_multikarya_db` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `pt_ar_multikarya_db`;

-- 1. Table users
CREATE TABLE IF NOT EXISTS `users` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `username` VARCHAR(100) NOT NULL UNIQUE,
  `passwordHash` VARCHAR(255) NOT NULL,
  `role` VARCHAR(50) NOT NULL DEFAULT 'sppg',
  `whatsapp` VARCHAR(50) DEFAULT '',
  `plainPassword` VARCHAR(100) DEFAULT '',
  `profilePic` LONGTEXT DEFAULT NULL,
  `customerId` INT DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. Table suppliers
CREATE TABLE IF NOT EXISTS `suppliers` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(255) NOT NULL,
  `code` VARCHAR(50) DEFAULT '',
  `phone` VARCHAR(50) DEFAULT '',
  `email` VARCHAR(100) DEFAULT '',
  `address` TEXT DEFAULT NULL,
  `notes` TEXT DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. Table barang
CREATE TABLE IF NOT EXISTS `barang` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `supplierId` INT NOT NULL,
  `code` VARCHAR(50) NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `unit` VARCHAR(50) NOT NULL DEFAULT 'SAK',
  `stock` DECIMAL(15,2) NOT NULL DEFAULT 0,
  `kategori` VARCHAR(100) DEFAULT 'Bahan Baku',
  `notes` TEXT DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4. Table price_lists
CREATE TABLE IF NOT EXISTS `price_lists` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `barangId` INT NOT NULL,
  `hargaBeli` DECIMAL(15,2) NOT NULL DEFAULT 0,
  `hargaJual` DECIMAL(15,2) NOT NULL DEFAULT 0,
  `effectiveDate` VARCHAR(50) NOT NULL,
  `effectiveDateEnd` VARCHAR(50) DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 5. Table customers
CREATE TABLE IF NOT EXISTS `customers` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(255) NOT NULL,
  `company` VARCHAR(255) DEFAULT '',
  `phone` VARCHAR(50) DEFAULT '',
  `email` VARCHAR(100) DEFAULT '',
  `address` TEXT DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 6. Table po
CREATE TABLE IF NOT EXISTS `po` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `poNumber` VARCHAR(100) NOT NULL,
  `supplierId` INT DEFAULT 1,
  `customerId` INT DEFAULT NULL,
  `poDate` VARCHAR(50) NOT NULL,
  `deliveryRequestDate` VARCHAR(50) DEFAULT '',
  `status` VARCHAR(50) NOT NULL DEFAULT 'Draft',
  `createdBy` VARCHAR(100) DEFAULT '',
  `createdByDetail` VARCHAR(255) DEFAULT '',
  `budgetLimit` DECIMAL(15,2) DEFAULT 0,
  `totalAmount` DECIMAL(15,2) DEFAULT 0,
  `deskripsi` TEXT DEFAULT NULL,
  `fileSuratJalan` LONGTEXT DEFAULT NULL,
  `receivedDate` VARCHAR(50) DEFAULT NULL,
  `receivedNotes` TEXT DEFAULT NULL,
  `receivedBy` VARCHAR(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 7. Table po_items
CREATE TABLE IF NOT EXISTS `po_items` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `poId` INT NOT NULL,
  `barangId` INT NOT NULL,
  `qty` DECIMAL(15,2) NOT NULL DEFAULT 1,
  `price` DECIMAL(15,2) NOT NULL DEFAULT 0,
  `total` DECIMAL(15,2) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 8. Table bukti_pembelian
CREATE TABLE IF NOT EXISTS `bukti_pembelian` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `buktiNumber` VARCHAR(100) NOT NULL,
  `refPoId` INT DEFAULT NULL,
  `poNumber` VARCHAR(100) DEFAULT '',
  `supplierId` INT NOT NULL,
  `receiveDate` VARCHAR(50) NOT NULL,
  `totalCost` DECIMAL(15,2) NOT NULL DEFAULT 0,
  `fileBukti` LONGTEXT DEFAULT NULL,
  `notes` TEXT DEFAULT NULL,
  `createdBy` VARCHAR(100) DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 9. Table bukti_pembelian_items
CREATE TABLE IF NOT EXISTS `bukti_pembelian_items` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `buktiPembelianId` INT NOT NULL,
  `barangId` INT NOT NULL,
  `qty` DECIMAL(15,2) NOT NULL DEFAULT 1,
  `unitCost` DECIMAL(15,2) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 10. Table invoice_jual
CREATE TABLE IF NOT EXISTS `invoice_jual` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `invoiceNumber` VARCHAR(100) NOT NULL,
  `refPoId` INT DEFAULT NULL,
  `customerId` INT NOT NULL,
  `invoiceDate` VARCHAR(50) NOT NULL,
  `dueDate` VARCHAR(50) DEFAULT '',
  `createdByDetail` VARCHAR(255) DEFAULT '',
  `discount` DECIMAL(15,2) DEFAULT 0,
  `taxRate` DECIMAL(5,2) DEFAULT 2,
  `subtotal` DECIMAL(15,2) DEFAULT 0,
  `taxAmount` DECIMAL(15,2) DEFAULT 0,
  `grandTotal` DECIMAL(15,2) DEFAULT 0,
  `hpp` DECIMAL(15,2) DEFAULT 0,
  `status` VARCHAR(50) DEFAULT 'Belum Lunas'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 11. Table invoice_jual_items
CREATE TABLE IF NOT EXISTS `invoice_jual_items` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `invoiceJualId` INT NOT NULL,
  `barangId` INT NOT NULL,
  `qty` DECIMAL(15,2) NOT NULL DEFAULT 1,
  `price` DECIMAL(15,2) NOT NULL DEFAULT 0,
  `total` DECIMAL(15,2) NOT NULL DEFAULT 0,
  `hpp` DECIMAL(15,2) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 12. Table settings
CREATE TABLE IF NOT EXISTS `settings` (
  `id` VARCHAR(50) PRIMARY KEY,
  `companyName` VARCHAR(255) DEFAULT '',
  `companyAddress` TEXT DEFAULT NULL,
  `companyPhone` VARCHAR(50) DEFAULT '',
  `companyEmail` VARCHAR(100) DEFAULT '',
  `taxRate` DECIMAL(5,2) DEFAULT 2,
  `bankName` VARCHAR(100) DEFAULT '',
  `bankAccount` VARCHAR(100) DEFAULT '',
  `bankHolder` VARCHAR(100) DEFAULT '',
  `logo` LONGTEXT DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 13. Table logs
CREATE TABLE IF NOT EXISTS `logs` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `timestamp` VARCHAR(50) NOT NULL,
  `action` VARCHAR(100) NOT NULL,
  `details` TEXT DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 14. Table chat_messages
CREATE TABLE IF NOT EXISTS `chat_messages` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `sender` VARCHAR(100) NOT NULL,
  `role` VARCHAR(50) NOT NULL,
  `channelId` VARCHAR(100) NOT NULL,
  `content` TEXT NOT NULL,
  `timestamp` VARCHAR(50) NOT NULL,
  `readBy` TEXT DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- SEED DATA AWAL
INSERT IGNORE INTO `users` (`id`, `username`, `passwordHash`, `role`, `whatsapp`, `plainPassword`, `profilePic`) VALUES
(1, 'admin', '8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918', 'admin', '081234567890', 'admin', ''),
(2, 'finance', '4b9a07b71900139b5b2db8106a72e817c80521e14930d6bf4381ca0406859346', 'finance', '081234567891', 'finance', ''),
(3, 'sppg', 'e85bdeea476b5717e1659b065f6f84f4270ab1475fde39d0052115bf69a42ff9', 'sppg', '081234567892', 'sppg', ''),
(4, 'mitra', 'ea62f22b7245d8b8e8f85f81ae0b2d6a5c13b3d4bb1f964ae962d3e147fa0d23', 'mitra', '081234567893', 'mitra', '');

