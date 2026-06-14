-- ============================================================
--  sportmanager_db.sql — Script completo para SportManager Pro
--  Importar en phpMyAdmin: http://localhost/phpmyadmin
-- ============================================================

CREATE DATABASE IF NOT EXISTS `sportmanager_db`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE `sportmanager_db`;

-- ─────────────────────────────────────────
-- TABLA: usuarios
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `usuarios` (
  `id`         INT          NOT NULL AUTO_INCREMENT,
  `nombre`     VARCHAR(100) NOT NULL,
  `email`      VARCHAR(150) NOT NULL UNIQUE,
  `password`   VARCHAR(255) NOT NULL,
  `rol`        ENUM('administrador','cliente','vendedor_snack','personal_mantenimiento','encargado_tienda') NOT NULL DEFAULT 'cliente',
  `activo`     TINYINT(1)   NOT NULL DEFAULT 1,
  `creado_en`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

INSERT INTO `usuarios` (`nombre`, `email`, `password`, `rol`) VALUES
('Carlos Admin',     'admin@canchas.com',   MD5('admin123'),    'administrador'),
('María González',   'cliente@canchas.com', MD5('cliente123'),  'cliente'),
('Pedro Ramírez',    'snack@canchas.com',   MD5('snack123'),    'vendedor_snack'),
('Juan Técnico',     'tecnico@canchas.com', MD5('tecnico123'),  'personal_mantenimiento'),
('Ana Tienda',       'tienda@canchas.com',  MD5('tienda123'),   'encargado_tienda');

-- ─────────────────────────────────────────
-- TABLA: canchas
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `canchas` (
  `id`         INT          NOT NULL AUTO_INCREMENT,
  `nombre`     VARCHAR(100) NOT NULL,
  `tipo`       VARCHAR(100) NOT NULL,
  `precio`     DECIMAL(8,2) NOT NULL DEFAULT 0.00,
  `estado`     ENUM('Disponible','Ocupada','Mantenimiento') NOT NULL DEFAULT 'Disponible',
  `creado_en`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

INSERT INTO `canchas` (`nombre`, `tipo`, `precio`, `estado`) VALUES
('Cancha 1', 'Fútbol 7',  50.00, 'Disponible'),
('Cancha 2', 'Fútbol 5',  40.00, 'Ocupada'),
('Cancha 3', 'Tenis',     60.00, 'Mantenimiento'),
('Cancha 4', 'Básquet',   30.00, 'Disponible');

-- ─────────────────────────────────────────
-- TABLA: reservas
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `reservas` (
  `id`           INT          NOT NULL AUTO_INCREMENT,
  `cancha_id`    INT          NOT NULL,
  `usuario_id`   INT          NOT NULL,
  `horario`      VARCHAR(100) NOT NULL,
  `fecha`        DATE         NOT NULL,
  `monto`        DECIMAL(8,2) NOT NULL,
  `estado`       ENUM('Confirmada','Cancelada') NOT NULL DEFAULT 'Confirmada',
  `creado_en`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`cancha_id`)  REFERENCES `canchas`(`id`),
  FOREIGN KEY (`usuario_id`) REFERENCES `usuarios`(`id`)
) ENGINE=InnoDB;

INSERT INTO `reservas` (`cancha_id`, `usuario_id`, `horario`, `fecha`, `monto`, `estado`) VALUES
(1, 2, '10:00 - 11:00', CURDATE(), 50.00, 'Confirmada'),
(4, 2, '14:00 - 15:00', CURDATE(), 30.00, 'Confirmada');

-- ─────────────────────────────────────────
-- TABLA: productos_snack
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `productos_snack` (
  `id`        INT          NOT NULL AUTO_INCREMENT,
  `nombre`    VARCHAR(100) NOT NULL,
  `precio`    DECIMAL(8,2) NOT NULL,
  `stock`     INT          NOT NULL DEFAULT 0,
  `activo`    TINYINT(1)   NOT NULL DEFAULT 1,
  `creado_en` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

INSERT INTO `productos_snack` (`nombre`, `precio`, `stock`) VALUES
('Gatorade Azul',   2.50, 15),
('Agua Mineral',    1.00, 30),
('Galletas Oreo',   1.50,  0),
('Barra Proteína',  3.00, 10),
('Jugo de Naranja', 2.00,  8),
('Refresco Cola',   1.75, 20);

-- ─────────────────────────────────────────
-- TABLA: ventas_snack
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `ventas_snack` (
  `id`          INT          NOT NULL AUTO_INCREMENT,
  `producto_id` INT          NOT NULL,
  `usuario_id`  INT          NOT NULL,
  `cantidad`    INT          NOT NULL DEFAULT 1,
  `total`       DECIMAL(8,2) NOT NULL,
  `creado_en`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`producto_id`) REFERENCES `productos_snack`(`id`),
  FOREIGN KEY (`usuario_id`)  REFERENCES `usuarios`(`id`)
) ENGINE=InnoDB;

-- ─────────────────────────────────────────
-- TABLA: implementos
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `implementos` (
  `id`              INT          NOT NULL AUTO_INCREMENT,
  `nombre`          VARCHAR(100) NOT NULL,
  `precio_alquiler` DECIMAL(8,2) NOT NULL,
  `precio_venta`    DECIMAL(8,2) NOT NULL,
  `stock`           INT          NOT NULL DEFAULT 0,
  `activo`          TINYINT(1)   NOT NULL DEFAULT 1,
  `creado_en`       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

INSERT INTO `implementos` (`nombre`, `precio_alquiler`, `precio_venta`, `stock`) VALUES
('Balón de Fútbol',  5.00, 25.00, 10),
('Raqueta de Tenis', 8.00, 80.00,  5),
('Balón de Básquet', 5.00, 30.00,  0),
('Chalecos (Set 10)',10.00,50.00,  3);

-- ─────────────────────────────────────────
-- TABLA: transacciones_implementos
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `transacciones_implementos` (
  `id`             INT          NOT NULL AUTO_INCREMENT,
  `implemento_id`  INT          NOT NULL,
  `usuario_id`     INT          NOT NULL,
  `tipo`           ENUM('Alquiler','Venta') NOT NULL,
  `monto`          DECIMAL(8,2) NOT NULL,
  `creado_en`      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`implemento_id`) REFERENCES `implementos`(`id`),
  FOREIGN KEY (`usuario_id`)    REFERENCES `usuarios`(`id`)
) ENGINE=InnoDB;

-- ─────────────────────────────────────────
-- TABLA: tickets_mantenimiento
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `tickets_mantenimiento` (
  `id`          INT          NOT NULL AUTO_INCREMENT,
  `cancha_id`   INT          NOT NULL,
  `reportado_por` INT        NOT NULL,
  `tipo`        VARCHAR(100) NOT NULL,
  `descripcion` TEXT,
  `estado`      ENUM('Pendiente','En Proceso','Completada') NOT NULL DEFAULT 'Pendiente',
  `avance`      INT          NOT NULL DEFAULT 0,
  `tecnico_id`  INT          DEFAULT NULL,
  `creado_en`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `cerrado_en`  DATETIME     DEFAULT NULL,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`cancha_id`)      REFERENCES `canchas`(`id`),
  FOREIGN KEY (`reportado_por`)  REFERENCES `usuarios`(`id`),
  FOREIGN KEY (`tecnico_id`)     REFERENCES `usuarios`(`id`)
) ENGINE=InnoDB;

INSERT INTO `tickets_mantenimiento` (`cancha_id`, `reportado_por`, `tipo`, `descripcion`, `estado`, `avance`, `tecnico_id`) VALUES
(3, 1, 'Daño', 'Red rota, requiere reemplazo',   'Pendiente',  0,  NULL),
(1, 2, 'Limpieza', 'Cancha sucia después del partido', 'En Proceso', 50, 4);

-- ─────────────────────────────────────────
-- TABLA: notificaciones
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `notificaciones` (
  `id`                 INT          NOT NULL AUTO_INCREMENT,
  `usuario_destino_id` INT          NOT NULL,
  `tipo`               VARCHAR(50)  NOT NULL,
  `mensaje`            TEXT         NOT NULL,
  `referencia_id`      INT          DEFAULT NULL,
  `leida`              TINYINT(1)   NOT NULL DEFAULT 0,
  `creado_en`          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  FOREIGN KEY (`usuario_destino_id`) REFERENCES `usuarios`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB;
