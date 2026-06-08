<?php

include("../conexion.php");

class Control_Reserva
{
    public function registrarReserva(
        $id_cliente,
        $id_cancha,
        $fecha,
        $hora,
        $productos
    )
    {
        global $conexion;

        $sql="
        INSERT INTO reserva
        (
            id_cliente,
            id_cancha,
            fecha,
            hora,
            productos
        )
        VALUES
        (
            '$id_cliente',
            '$id_cancha',
            '$fecha',
            '$hora',
            '$productos'
        )
        ";

        return mysqli_query(
            $conexion,
            $sql
        );
    }
}
?>