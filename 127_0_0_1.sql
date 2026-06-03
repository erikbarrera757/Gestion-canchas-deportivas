-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 03-06-2026 a las 15:49:22
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `reserva_canchas`
--
CREATE DATABASE IF NOT EXISTS `reserva_canchas` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE `reserva_canchas`;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cancha`
--

CREATE TABLE `cancha` (
  `id_cancha` int(11) NOT NULL,
  `nombre` varchar(50) NOT NULL,
  `tipo` varchar(50) NOT NULL,
  `precio` decimal(10,2) NOT NULL,
  `estado` varchar(20) DEFAULT 'Disponible'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `cancha`
--

INSERT INTO `cancha` (`id_cancha`, `nombre`, `tipo`, `precio`, `estado`) VALUES
(1, 'Cancha Futbol 1', 'Futbol', 120.00, 'Disponible'),
(2, 'Cancha Futbol 2', 'Futbol', 120.00, 'Disponible'),
(3, 'Cancha Futsal 1', 'Futsal', 90.00, 'Disponible'),
(4, 'Cancha Futsal 2', 'Futsal', 90.00, 'Disponible'),
(5, 'Cancha Voley 1', 'Voley', 70.00, 'Disponible'),
(6, 'Cancha Voley 2', 'Voley', 70.00, 'Disponible'),
(7, 'Cancha Basquet 1', 'Basquet', 80.00, 'Disponible'),
(8, 'Cancha Basquet 2', 'Basquet', 80.00, 'Disponible');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cliente`
--

CREATE TABLE `cliente` (
  `id_cliente` int(11) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `apellido` varchar(100) NOT NULL,
  `telefono` varchar(20) DEFAULT NULL,
  `correo` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `cliente`
--

INSERT INTO `cliente` (`id_cliente`, `nombre`, `apellido`, `telefono`, `correo`) VALUES
(1, 'Carlos', 'Rocabado', '77777777', 'carlos@gmail.com'),
(2, 'Juan', 'Perez', '66666666', 'juan@gmail.com'),
(3, 'Maria', 'Lopez', '75555555', 'maria@gmail.com'),
(4, 'Jose', 'Fernandez', '74444444', 'jose@gmail.com'),
(5, 'Ana', 'Gutierrez', '73333333', 'ana@gmail.com');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `detalle_reserva`
--

CREATE TABLE `detalle_reserva` (
  `id_detalle` int(11) NOT NULL,
  `id_reserva` int(11) NOT NULL,
  `id_producto` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `detalle_reserva`
--

INSERT INTO `detalle_reserva` (`id_detalle`, `id_reserva`, `id_producto`) VALUES
(1, 1, 1),
(2, 1, 2),
(3, 2, 3),
(4, 3, 4),
(5, 3, 5),
(6, 4, 1),
(7, 4, 2),
(8, 4, 5),
(9, 5, 1),
(10, 5, 2),
(11, 5, 5),
(12, 6, 1),
(13, 6, 2),
(14, 6, 5),
(15, 7, 1),
(16, 7, 2),
(17, 7, 5);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `producto`
--

CREATE TABLE `producto` (
  `id_producto` int(11) NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `precio` decimal(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `producto`
--

INSERT INTO `producto` (`id_producto`, `nombre`, `precio`) VALUES
(1, 'Balon', 20.00),
(2, 'Bebida', 10.00),
(3, 'Conos de Entrenamiento', 15.00),
(4, 'Petos', 25.00),
(5, 'Arbitro', 50.00);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `reserva`
--

CREATE TABLE `reserva` (
  `id_reserva` int(11) NOT NULL,
  `id_cliente` int(11) NOT NULL,
  `id_cancha` int(11) NOT NULL,
  `fecha` date NOT NULL,
  `hora` varchar(20) NOT NULL,
  `total` decimal(10,2) DEFAULT 0.00
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `reserva`
--

INSERT INTO `reserva` (`id_reserva`, `id_cliente`, `id_cancha`, `fecha`, `hora`, `total`) VALUES
(1, 1, 1, '2026-06-10', '08:00', 120.00),
(2, 2, 2, '2026-06-10', '08:00', 120.00),
(3, 3, 2, '2026-05-15', '08:00', 90.00),
(4, 1, 2, '2026-06-17', '08:00', 0.00),
(5, 1, 1, '2026-06-03', '08:00', 0.00),
(6, 1, 2, '2026-08-15', '08:00', 200.00),
(7, 1, 2, '2026-08-17', '08:00', 200.00);

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `cancha`
--
ALTER TABLE `cancha`
  ADD PRIMARY KEY (`id_cancha`);

--
-- Indices de la tabla `cliente`
--
ALTER TABLE `cliente`
  ADD PRIMARY KEY (`id_cliente`);

--
-- Indices de la tabla `detalle_reserva`
--
ALTER TABLE `detalle_reserva`
  ADD PRIMARY KEY (`id_detalle`),
  ADD KEY `id_reserva` (`id_reserva`),
  ADD KEY `id_producto` (`id_producto`);

--
-- Indices de la tabla `producto`
--
ALTER TABLE `producto`
  ADD PRIMARY KEY (`id_producto`);

--
-- Indices de la tabla `reserva`
--
ALTER TABLE `reserva`
  ADD PRIMARY KEY (`id_reserva`),
  ADD KEY `id_cliente` (`id_cliente`),
  ADD KEY `id_cancha` (`id_cancha`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `cancha`
--
ALTER TABLE `cancha`
  MODIFY `id_cancha` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT de la tabla `cliente`
--
ALTER TABLE `cliente`
  MODIFY `id_cliente` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `detalle_reserva`
--
ALTER TABLE `detalle_reserva`
  MODIFY `id_detalle` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=18;

--
-- AUTO_INCREMENT de la tabla `producto`
--
ALTER TABLE `producto`
  MODIFY `id_producto` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT de la tabla `reserva`
--
ALTER TABLE `reserva`
  MODIFY `id_reserva` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `detalle_reserva`
--
ALTER TABLE `detalle_reserva`
  ADD CONSTRAINT `detalle_reserva_ibfk_1` FOREIGN KEY (`id_reserva`) REFERENCES `reserva` (`id_reserva`) ON DELETE CASCADE,
  ADD CONSTRAINT `detalle_reserva_ibfk_2` FOREIGN KEY (`id_producto`) REFERENCES `producto` (`id_producto`);

--
-- Filtros para la tabla `reserva`
--
ALTER TABLE `reserva`
  ADD CONSTRAINT `reserva_ibfk_1` FOREIGN KEY (`id_cliente`) REFERENCES `cliente` (`id_cliente`),
  ADD CONSTRAINT `reserva_ibfk_2` FOREIGN KEY (`id_cancha`) REFERENCES `cancha` (`id_cancha`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
