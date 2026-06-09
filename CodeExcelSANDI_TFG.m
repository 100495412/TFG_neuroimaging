%% --- SCRIPT PARA CREAR EXCEL FINAL: HIPOCAMPO 2 Y CUERPO CALLOSO (SANDI) ---
clear all; close all;

% --- CONFIGURACIÓN DE RUTAS LOCALES (CARPETA DE SANDI) ---
ruta_base_txt     = 'C:\Users\lolan\Downloads\SANDI\Resultados_SANDI_CC'; % Ruta corregida para SANDI
ruta_excel_datos  = 'C:\Users\lolan\Downloads\Diffusion_times\Datos.xlsx';

% Guardamos el Excel en la carpeta de SANDI con un nombre único descriptivo
ruta_salida_excel = fullfile(ruta_base_txt, 'all_SANDI_CC_bueno.xlsx');

% --- Leer Excel con metadatos de ratones ---
if exist(ruta_excel_datos, 'file')
    T = readtable(ruta_excel_datos);
else
    % Comprobación por si el archivo Datos.xlsx está metido en la subcarpeta
    ruta_alternativa = 'C:\Users\lolan\Downloads\Diffusion_times\Diffusion_times\Datos.xlsx';
    if exist(ruta_alternativa, 'file')
        T = readtable(ruta_alternativa);
    else
        error('ERROR: No encuentro el archivo "Datos.xlsx". Por favor, asegúrate de que se encuentra en la carpeta: C:\Users\lolan\Downloads\Diffusion_times\');
    end
end

% --- Renombrar columnas para mayor claridad ---
T.Properties.VariableNames = {'MouseName','MouseID','SexText','SexNum','DietText','DietNum'};

% Inicializar tabla final
agrupacion_TOTAL = [];

fprintf('--- GENERANDO BASE DE DATOS FINAL SANDI CC: all_SANDI_CC_bueno.xlsx ---\n\n');

% --- Loop por cada ratón ---
for i = 1:height(T)
    nombre_raton = T.MouseName{i};
    mouse_id    = T.MouseID(i);
    sex_num     = T.SexNum(i);
    diet_num    = T.DietNum(i);
    
    % --- NOTA: Se ha ELIMINADO el descarte de R87. Ahora se procesa normalmente ---
    
    % Nombre del archivo TXT de la carpeta de SANDI
    nombre_archivo_txt = sprintf('%s_SANDI_Data.txt', nombre_raton);
    ruta_completa_txt = fullfile(ruta_base_txt, nombre_archivo_txt);
    
    if exist(ruta_completa_txt, 'file')
        % Leer datos del TXT (contiene IDs 1, 2 para hip2 y 3 para ccn)
        data = readmatrix(ruta_completa_txt);
        num_pixeles = size(data,1);
        
        if num_pixeles == 0, continue; end
        
        % Crear columnas repetidas con los metadatos de este ratón
        mouse_v = repmat(mouse_id, num_pixeles,1);
        sex_v   = repmat(sex_num, num_pixeles,1);
        diet_v  = repmat(diet_num, num_pixeles,1);
        
        % Crear tabla temporal asignando las columnas exactas de SANDI:
        % data(:,7) es 'fs' (fracción soma) y data(:,8) es 'rs' (radio soma)
        tabla_actual = table(mouse_v, sex_v, diet_v, data(:,1), data(:,2), data(:,3), ...
                             data(:,4), data(:,5), data(:,6), data(:,7), data(:,8), ...
                             'VariableNames', {'MouseID','Sex','Diet','ROI','X','Y','di','de','f','fs','rs'});
        
        % Concatenar al total
        agrupacion_TOTAL = [agrupacion_TOTAL; tabla_actual];
        
        fprintf('[OK] %s -> %d píxeles añadidos.\n', nombre_raton, num_pixeles);
    else
        fprintf('[!] No se encontró el archivo de datos en la carpeta SANDI para: %s\n', nombre_raton);
    end
end

% --- Guardar Excel final ---
if ~isempty(agrupacion_TOTAL)
    try
        writetable(agrupacion_TOTAL, ruta_salida_excel);
        fprintf('\n¡PROCESO COMPLETADO!\nArchivo creado: %s\nTotal filas en la base de datos: %d\n', ...
                ruta_salida_excel, size(agrupacion_TOTAL,1));
    catch
        fprintf('\n[ERROR] No se pudo guardar el Excel. ¡Cierra el archivo "all_SANDI_CC_bueno.xlsx" si lo tienes abierto!\n');
    end
else
    fprintf('\n[ERROR] No hay datos procesados en la carpeta SANDI para exportar.\n');
end