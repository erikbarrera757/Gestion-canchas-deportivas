<?php

class Reserva
{
    public $id_reserva;
    public $id_cliente;
    public $id_cancha;
    public $fecha;
    public $hora;
    public $productos;

    public function __construct(
        $id_reserva,
        $id_cliente,
        $id_cancha,
        $fecha,
        $hora,
        $productos
    )
    {
        $this->id_reserva=$id_reserva;
        $this->id_cliente=$id_cliente;
        $this->id_cancha=$id_cancha;
        $this->fecha=$fecha;
        $this->hora=$hora;
        $this->productos=$productos;
    }
}

?>