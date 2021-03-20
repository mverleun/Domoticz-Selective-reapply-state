# Domoticz reapply state

Selective reapply a state in Domoticz, useful for 443.92 Mhz devices and others without feedback.

With many 443.92 Mhz devices, RF-Link or RFXCom controlled, such as Klik-Aan-Klik-Uit (kika), Home Easy EU, Unitec, Silvercrest and many more it could be necessary to resend the desired state periodically. This because the control mechanism is a so called open loop instead of a closed loop.

## Closed loop vs open loop

Closed loop control systems do check if state changes actually propagate to the device. Communication has to be bi-directional to achieve this.

Unidrectional communication with (cheap) 433.92 Mhz switches is a kind of 'send and hope' technique. It often works, but not always.
Depending on distance, walls and other factors that negatively impact the signal strength reliabilty may decrease.
But also interference with other signals that are transmitted at the same time make this technique less reliable.

## Re-apply state

The alternative is to, periodically, re-transmit the desired state which will eventually correct the state.

## Limit retransmissions

Limit retransmissions as much as possible to avoid interference with other signals. 
This script will call the Domoticz API to obtain more information then is available within the standaard LUA tables that are present.
With an if-statement devices are selected as selective as possible for which retransmission is desirable.

## Timed script

The LUA script is a timed script in Domoticz. This means that the script is executed every minute. 
If the state of a device changed within a certain interval this script will not re-apply the same state until that interval has expired.

But even when the interval has expired the device has to wait until the next run before the state is re-applied.
