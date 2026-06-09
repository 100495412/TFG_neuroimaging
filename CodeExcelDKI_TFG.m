%% --- SCRIPT PARA CREAR EXCEL FINAL DE TODOS LOS RATONES Y TIEMPOS DE DIFUSIÓN (CON CC) ---
clear all; close all;

% --- CONFIGURACIÓN DE RUTAS ---
ruta_base_txt = 'S:\mdnovalbos\info_services\blizarbe_lab_share\TFG Lola\Resultados_filtrados';
ruta_excel_datos = 'S:\mdnovalbos\info_services\blizarbe_lab_share\TFG Lola\NEXI\Diffusion_times/Datos.xlsx';
ruta_salida_excel = fullfile(ruta_base_txt, 'all_DTI_DKI_bueno.xlsx');

% --- Leer Excel con metadatos de ratones ---
T = readtable(ruta_excel_datos);

% --- Renombrar columnas para mayor claridad ---
T.Properties.VariableNames = {'MouseName','MouseID','SexText','SexNum','DietText','DietNum'};

% --- Lista de tiempos de difusión ---
tiempos = {'DKI_1_1','DKI_2_1','DKI_3_1','DKI_4_1'};

% Inicializar tabla final
agrupacion_TOTAL = [];

fprintf('--- GENERANDO BASE DE DATOS FINAL DKI + CC: all_DTI_DKI_bueno.xlsx ---\n\n');

% --- Loop por cada ratón ---
for i = 1:height(T)
    nombre_raton = T.MouseName{i};
    mouse_id    = T.MouseID(i);
    sex_num     = T.SexNum(i);
    diet_num    = T.DietNum(i);
    
    for t = 1:length(tiempos)
        tiempo_act = tiempos{t};
        
        % Nombre del archivo TXT generado previamente
        nombre_archivo_txt = sprintf('%s_%s_Filtered.txt', nombre_raton, tiempo_act);
        ruta_completa_txt = fullfile(ruta_base_txt, tiempo_act, nombre_archivo_txt);
        
        if exist(ruta_completa_txt, 'file')
            % Leer datos del TXT
            data = readmatrix(ruta_completa_txt);
            num_pixeles = size(data,1);
            
            if num_pixeles == 0, continue; end
            
            % Columnas de metadatos
            mouse_v = repmat(mouse_id, num_pixeles,1);
            sex_v   = repmat(sex_num, num_pixeles,1);
            diet_v  = repmat(diet_num, num_pixeles,1);
            tiempo_v = repmat({tiempo_act}, num_pixeles,1);
            
            % Crear tabla temporal mapeando las 10 columnas del TXT extraídas
            % data(:,1)=ROI, data(:,2)=X, data(:,3)=Y, data(:,4)=MD, data(:,5)=AD,
            % data(:,6)=RD, data(:,7)=AK, data(:,8)=RK, data(:,9)=MK, data(:,10)=FA_DKI
            tabla_actual = table(mouse_v, sex_v, diet_v, tiempo_v, data(:,1), data(:,2), data(:,3), ...
                                 data(:,4), data(:,5), data(:,6), data(:,7), data(:,8), data(:,9), data(:,10), ...
                                 'VariableNames', {'MouseID','Sex','Diet','Tiempo','ROI','X','Y','MD','AD','RD','AK','RK','MK','FA_DKI'});
            
            % Concatenar al total
            agrupacion_TOTAL = [agrupacion_TOTAL; tabla_actual];
            
            fprintf('[OK] %s (%s) -> %d píxeles añadidos.\n', nombre_raton, tiempo_act, num_pixeles);
        else
            fprintf('[!] No se encontró el archivo: %s\n', ruta_completa_txt);
        end
    end
end

% --- Guardar Excel final ---
if ~isempty(agrupacion_TOTAL)
    try
        writetable(agrupacion_TOTAL, ruta_salida_excel);
        fprintf('\n¡PROCESO COMPLETADO!\nArchivo creado con Cuerpo Calloso: %s\nTotal filas: %d\n', ...
                ruta_salida_excel, size(agrupacion_TOTAL,1));
    catch
        fprintf('\n[ERROR] No se pudo guardar el Excel. ¡Cierra el archivo "all_DTI_DKI_bueno.xlsx" si lo tienes abierto!\n');
    end
else
    fprintf('\n[ERROR] No hay datos para exportar.\n');
end