// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

contract Auction {
    address private owner;
    uint256 private startTime;
    uint256 private stopTime;
    bool private auctionEnded = false;

    struct Bid {
        address bider;
        uint256 value;
        uint256 bidTime;
    }

    Bid[] private offers; // Historial de todas las ofertas realizadas
    Bid private winner; // La oferta ganadora final
    mapping(address => Bid[]) private bidsByBider; // Historial de ofertas por cada postor
    mapping(address => uint256) private pendingWithdrawals;

    constructor () {
        owner = msg.sender;
        startTime = block.timestamp;
        stopTime = startTime + 7 days; // Subasta de 7 días inicialmente
    }

    // --- Eventos ---
    event NewOffer(address indexed bider, uint256 amount, uint256 bidTime);
    event AuctionEnded(address indexed winnerAddress, uint256 winnerValue);
    event FundsWithdrawn(address indexed bider, uint256 amount);

    // --- Modificadores ---
    modifier onlyOwner() {
        require(owner == msg.sender, "Solo el propietario puede ejecutar esto.");
        _;
    }

    modifier isActiveCheck() {
        require(isActive(), "La subasta ya no esta activa.");
        _;
    }

    modifier isNotActiveCheck() {
        require(!isActive(), "La subasta aun esta activa.");
        _;
    }

    // Valida la oferta según si es la primera o subsiguiente
    modifier isValidBid() {
        if (offers.length == 0) {
            require(msg.value >= 1 ether, "La oferta inicial minima es 1 Ether.");
        } else {
            require(msg.value >= (offers[offers.length - 1].value * 105) / 100, "No fue aceptada la oferta, el monto es muy bajo (min. 5% mas que la anterior).");
        }
        _;
    }

    // --- Funciones Internas/Vista (Helpers) ---

    function isActive() internal view returns (bool) {
        return block.timestamp < stopTime && !auctionEnded;
    }

    function withdrawFundsForInternalUseOnly(bool _commission, address _currentAcount) internal {
        uint256 amount = pendingWithdrawals[_currentAcount];
        bool transactionFlag;

        if (_commission) {
            if (amount > 0) {
                // Cobra una comision del 2%
                amount -= (amount * 2) / 100;
                transactionFlag = true;
            }
        } else {
            require(amount > 0, "No tienes fondos pendientes para retirar.");
            transactionFlag = true;
        }

        if (transactionFlag) {
            pendingWithdrawals[_currentAcount] = 0; // Resetear el monto antes de la transferencia para evitar re-entrancy

            (bool success, ) = payable(_currentAcount).call{value: amount}("");
            require(success, "Fallo al enviar Ether de vuelta.");

            emit FundsWithdrawn(_currentAcount, amount);
        }

    }

    // --- Funciones Principales ---

    // Función para hacer una oferta
    function addOffer() external payable isActiveCheck isValidBid {
        // La oferta actual se convierte en la nueva oferta más alta (por ahora)
        // Guardar la oferta anterior para posible reembolso
        if (winner.bider != address(0)) { // Si ya hay una oferta "ganadora"
            // Agrega a los fondos pendientes de retirar al postor anterior
            // Esto asume que winner siempre es la oferta a batir.
            pendingWithdrawals[winner.bider] += winner.value;
        }

        Bid memory newBid = Bid({
            bider: msg.sender,
            value: msg.value,
            bidTime: block.timestamp
        });

        offers.push(newBid); // Añadir al historial global de ofertas
        bidsByBider[msg.sender].push(newBid); // Añadir al historial de ofertas por postor

        winner = newBid; // Actualizar el 'ganador' provisional
        stopTime += 10 minutes; // Extiende la subasta por 10 minutos
        
        emit NewOffer(msg.sender, msg.value, block.timestamp);
    }

    // Función para finalizar la subasta y determinar el ganador
    function endAuction() external onlyOwner isNotActiveCheck {
        require(!auctionEnded, "La subasta ya ha finalizado."); // Evitar llamar múltiples veces

        auctionEnded = true; // Marcar la subasta como terminada permanentemente

        // Lógica para el ganador (si no hubo ofertas, winner.bider será address(0))
        if (offers.length > 0) {
            // Si hay un ganador (es decir, hubo al menos una oferta válida)
            if (winner.bider != address(0)) {
                // El valor del ganador se queda en el contrato.
                // El resto del Ether de los perdedores es reembolsado.
                for (uint i = 0; i < offers.length; i++) { 
                    withdrawFundsForInternalUseOnly(true, offers[i].bider);
                }
            }
        }

        emit AuctionEnded(winner.bider, winner.value);
    }


    // Permite a los participantes retirar los fondos de sus ofertas anteriores
    function withdrawFunds() external {
        withdrawFundsForInternalUseOnly(false, msg.sender);
    }


    // --- Getters ---

    // Devolver la oferta ganadora y sus detalles
    function showWinner() external view returns(Bid memory) {
        require(auctionEnded && winner.bider != address(0), "El ganador aun no ha sido determinado o la subasta no ha terminado.");
        return winner;
    }

    // Devolver todas las ofertas realizadas
    function showAllOffers() external view returns (Bid[] memory) {
        return offers;
    }

    // Devolver ofertas de un postor específico
    function showBidsByBider(address _bider) external view returns (Bid[] memory) {
        return bidsByBider[_bider];
    }

    // Obtener el propietario
    function getOwner() external view returns (address) {
        return owner;
    }

    // Obtener el tiempo de finalización
    function getStopTime() external view returns (uint256) {
        return stopTime;
    }

    // Obtener fondos pendientes de un usuario
    function getPendingWithdrawal(address _bider) external view returns (uint256) {
        return pendingWithdrawals[_bider];
    }


    // Funcion para retirar todo el Ether del contrato
    function withdrawContractBalanceToOwner() external onlyOwner isNotActiveCheck{
        // Balance total del contrato
        uint256 contractBalance = address(this).balance;

        // Asegurarse de que haya Ether para enviar
        require(contractBalance > 0, "No hay Ether en el contrato para retirar.");

        // Realiza la transferencia al propietario
        (bool success, ) = payable(owner).call{value: contractBalance}("");
        require(success, "Fallo al enviar el balance del contrato al propietario.");

        emit FundsWithdrawn(owner, contractBalance); 
    }

    // Parada de emergencia
    function emergencyStop() external onlyOwner isActiveCheck {
        stopTime = block.timestamp;
    }

    // Función para recibir Ether directamente sin llamar a una función específica
    receive() external payable {
        // Esto es útil si alguien accidentalmente envía Ether al contrato sin llamar a addOffer
        // o si un contrato envía Ether sin especificar una función.
        // Mas ethercito para papa jajaja
    }

    // Función de fallback para llamadas a funciones no existentes o sin data
    fallback() external payable {
        // Venga ethercito acumulemos dinerito jajaja
    }
}