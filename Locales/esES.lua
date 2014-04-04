-- esES localization
local L = LibStub("AceLocale-3.0"):NewLocale("PetHealthBroker", "esES")

if not L then return end

-- Title for DataBroker
L['Pet Health'] = 'Salud de Mascota'

-- Configuration
L['Show Percentages'] = 'Mostrar Porcentajes'
L['Show Percentages instead of current/max health'] = 'Mostrar Porcentages en lugar de salud actual/máxima'
L['Show Rarity'] = 'Mostrar Rareza'
L['Colorize max health or percent sign based on pet rarity'] = 'Colorear la salud máxima o el simbolo de tanto porciento basándonos en la rareza de la mascota'
L['Show Cooldown'] = 'Mostrar "Cooldown"'
L['Show cooldown time for Revive Battle Pets spell in bar'] = 'Mostrar el tiempo de reutilización restante de la habilidad de Revivir Mascotas'
-- Revive Battle Pets availability notification config
L['Notify Availability'] = 'Notificar disponibilidad'
L['Notify the player when cooldown time finishes'] = 'Notificar al jugador cuando el tiempo de reutilización de la habilidad acaba'
L['None'] = 'Ninguna'
L['With Level Up sound'] = 'Con sonido Subir de Nivel'
L['In chat'] = 'En el chat'
L['Both'] = 'Ambos'
-- Click configuration config
L['One Click Rearrange'] = 'Reorganizar con un Click'
L['Nothing'] = 'Nada'
L['Healthiest first (absolute)'] = 'Más Salud Primero (absoluta)'
L['Healthiest first (relative)'] = 'Más Salud Primero (relativa)'
L['Lowest level first'] = 'Menor Nivel Primero'
L['Highest level first'] = 'Mayor Nivel Primero'
L['Control Left Click'] = 'Control Click Izquierdo'
L['Action to perform when Control Left Clicking in the text'] = 'Modo de reorganizar las pets activas al pulsar Control Click Izquierdo sobre el texto'
L['Alt Left Click'] = 'Alt Click Derecho'
L['Action to perform when Alt Left Clicking in the text'] = 'Modo de reorganizar las pets activas al pulsar Alt Click Izquierdo sobre el texto'

-- In chat notification of RBP ready; %s us RBP name
L['%s is ready'] = '%s está listo'

-- Click instructions
L['Left Click to open Pet Journal'] = 'Click Izquierdo para abrir el Diario de Mascotas'
L['Right Click to open Options'] = 'Click Derecho para abrir Opciones'
L['Control-Left Click to Rearrange %s'] = 'Control Click Izquierdo para Reorganizar %s'
L['Alt-Left Click to Rearrange %s'] = 'Alt Click Izquierdo para Reorganizar %s'
