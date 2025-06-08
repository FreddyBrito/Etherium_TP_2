# Trabajo Final - Módulo 2: Smart Contract de Subasta

Este documento detalla el diseño y las funcionalidades del Smart Contract de Subasta desarrollado como parte del Trabajo Final del Módulo 2. El contrato permite realizar subastas de activos digitales de forma segura y transparente en la blockchain.

## 🎯 Requisitos Generales

El Smart Contract de Subasta cumple con los siguientes requisitos generales:

* **Publicado en la red Sepolia:** El contrato ha sido desplegado en la red de pruebas Sepolia.
* **Verificado:** El código fuente del contrato ha sido verificado y es accesible públicamente.

**URL del Contrato Publicado y Verificado:**
0x7787aB831287AE254491EE4CfF89802E6828899a
[https://sepolia.etherscan.io/address/0x7787aB831287AE254491EE4CfF89802E6828899a#code]


**Repositorio Público en GitHub:**
[https://github.com/FreddyBrito/Etherium_TP_2/blob/main/auction.sol]

## ⚙️ Funcionalidades Requeridas

A continuación, se describen las funcionalidades clave implementadas en el Smart Contract:

### 📦 Constructor

El constructor del contrato (`constructor`) se encarga de inicializar la subasta con los parámetros necesarios para su correcto funcionamiento, tales como la duración de la subasta, el precio inicial y la dirección del propietario.

### 🏷️ Función para Ofertar (`placeBid`)

Esta función permite a los participantes realizar ofertas por el artículo en subasta. Una oferta se considera válida si cumple con las siguientes condiciones:

* **Incremento Mínimo:** La nueva oferta debe ser al menos un 5% mayor que la oferta más alta actual.
* **Subasta Activa:** La oferta debe realizarse mientras la subasta se encuentra en un estado activo.

Las ofertas deben ser depositadas en el contrato y estar asociadas a las direcciones de los oferentes.

### 🥇 Mostrar Ganador (`getWinner`)

Esta función devuelve la dirección del oferente ganador y el valor de su oferta ganadora una vez finalizada la subasta.

### 📜 Mostrar Ofertas (`getAllBids`)

Esta función proporciona una lista completa de todos los oferentes que han participado en la subasta, junto con los montos de sus respectivas ofertas.

### 💸 Devolver Depósitos (`withdrawDeposits`)

Una vez que la subasta ha finalizado, esta función permite a los oferentes no ganadores recuperar sus depósitos. Se descontará una comisión del 2% sobre el valor del depósito para los oferentes no ganadores.

### 💰 Manejo de Depósitos

Todas las ofertas realizadas deben ir acompañadas de un depósito de ether, el cual queda retenido en el contrato. Estos depósitos están directamente asociados a la dirección de la billetera del oferente.

## 📢 Eventos Requeridos

El contrato emite los siguientes eventos para comunicar los cambios de estado a los participantes y facilitar la interacción con aplicaciones descentralizadas (dApps):

* **`NewBid(address bidder, uint256 amount)`:** Emitido cada vez que se realiza una nueva oferta válida.
* **`AuctionEnded(address winner, uint256 winningBid)`:** Emitido cuando la subasta finaliza, indicando el ganador y el monto de la oferta ganadora.

## 🚀 Funcionalidades Avanzadas

### 🔁 Reembolso Parcial (`partialRefund`)

Durante el transcurso de la subasta, los participantes tienen la capacidad de solicitar un reembolso parcial. Esta funcionalidad permite retirar el importe que excede su última oferta válida.

**Ejemplo:**
| Tiempo | Usuario   | Oferta |
| :----- | :-------- | :----- |
| T0     | Usuario 1 | 1 ETH  |
| T1     | Usuario 2 | 2 ETH  |
| T2     | Usuario 1 | 3 ETH  |

En el ejemplo anterior, en el tiempo T2, el "Usuario 1" puede solicitar el reembolso de su oferta inicial de 1 ETH (correspondiente a T0), ya que su nueva oferta de 3 ETH es la última válida.

## 🧠 Consideraciones Adicionales

* **Modificadores:** Se han utilizado modificadores (`modifier`) en el contrato para aplicar restricciones y validaciones de forma eficiente y reutilizable.
* **Incremento de Oferta:** Para que una nueva oferta sea considerada válida y supere a la actual mejor oferta, debe ser superior al menos en un 5%.
* **Extensión de Plazo:** Si una oferta válida se realiza dentro de los últimos 10 minutos del plazo original de la subasta, el tiempo de la subasta se extenderá automáticamente por 10 minutos adicionales para permitir a otros participantes la oportunidad de responder.
* **Seguridad y Robustez:** El contrato ha sido diseñado con un enfoque en la seguridad y la robustez, manejando adecuadamente los errores y las posibles situaciones excepcionales para garantizar un comportamiento predecible y confiable.
* **Eventos para Comunicación:** La implementación de eventos es crucial para comunicar los cambios de estado de la subasta a los participantes y a las dApps que interactúen con el contrato.
* **Documentación Exhaustiva:** Este archivo README.md proporciona una documentación clara y completa del contrato, explicando sus funciones, variables y eventos para facilitar su comprensión y uso.