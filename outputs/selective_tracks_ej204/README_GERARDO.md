# Display Selectivo para Gerardo

La simulación física no se reduce. El muón, el centelleo, la absorción, la reflectividad, la PDE, la geometría y el transporte óptico siguen siendo exactamente los mismos. Lo único que cambia es cuántas trayectorias G4Trajectory se almacenan para visualización.

Se usan valores de `/display/maxOpticalTrajectories` de 5, 20 o 100. Los fotones que no entran en el display siguen siendo transportados normalmente y siguen contribuyendo a los hits ROOT.

La invariancia física fue verificada comparando los hashes SHA256 del contenido completo de `sipm_hits` entre `x0_n5`, `x0_n20` y `x0_n100`: los tres son idénticos.

Colores:
- Rojo: muón.
- Cian: trayectorias ópticas seleccionadas.

Cada quiebre de una línea cian representa un cambio de dirección en un step, frecuentemente asociado a una interacción con una frontera óptica.

Interpretación de posiciones:
- `x = -690 mm`: cerca del extremo izquierdo.
- `x = -400 mm`: posición intermedia.
- `x = 0 mm`: centro de la barra.

Lectura recomendada:
- `N = 5`: permite seguir trayectorias individuales.
- `N = 20`: vista principal recomendada para presentación.
- `N = 100`: muestra una distribución más representativa, aunque más densa.

Importante: las trayectorias seleccionadas no son una muestra estadísticamente aleatoria; son las primeras N trayectorias ópticas creadas en el evento para una semilla fija.
