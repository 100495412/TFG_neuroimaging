clear all; close all;

% --- CONFIGURACIÓN DE RUTAS LOCALES ---
ruta_base_proyecto = 'C:\Users\lolan\Downloads\Diffusion_times\Diffusion_times';
ruta_funciones      = 'C:\Users\lolan\Downloads\Diffusion_times'; 
ruta_destino        = 'C:\Users\lolan\Downloads\Diffusion_times\Resultados_NEXI_CC';

% Añadimos la ruta de las funciones y todas sus subcarpetas
if exist(ruta_funciones, 'dir')
    addpath(genpath(ruta_funciones)); 
else
    error('No se encuentra la carpeta de funciones en %s', ruta_funciones);
end

if ~exist(ruta_destino, 'dir'), mkdir(ruta_destino); end

elementos = dir(fullfile(ruta_base_proyecto, 'R*'));
lista_ratones = elementos([elementos.isdir]);

fprintf('--- INICIANDO EXTRACCIÓN DE MÉTRICAS NEXI (HIPOCAMPO 2 Y CUERPO CALLOSO) ---\n\n');

for i = 1:length(lista_ratones)
    nombre_raton = lista_ratones(i).name;
    
    if strcmp(nombre_raton, 'R87') || contains(nombre_raton, 'Resultados')
        continue; 
    end
    
    ruta_carpeta_unica = fullfile(ruta_base_proyecto, nombre_raton, 'Nexi_results_fixedDi_NPA');
    if ~exist(ruta_carpeta_unica, 'dir'), continue; end
    
    cd(ruta_carpeta_unica);
    f_archivos = dir('*.nii*');
    
    if isempty(f_archivos), continue; end
    
    % Función de alineación estricta
    cargar_correcto = @(patron) flip(permute(getfield(load_nii(char(f_archivos(find(contains({f_archivos.name}, patron), 1)).name)), 'img'), [1 3 2]), 2);
    
    % Carga de mapas paramétricos
    try
        di_m   = cargar_correcto('nexi_rice_mean_di');
        de_m   = cargar_correcto('nexi_rice_mean_de');
        f_m    = cargar_correcto('nexi_rice_mean_f');
        tex_m  = cargar_correcto('nexi_rice_mean_t_ex');
    catch ME
        fprintf('Error en mapas de %s: %s\n', nombre_raton, ME.message);
        continue; 
    end
    
    % --- SELECCIÓN EXCLUSIVA DE ROIs ---
    % Reducimos la lista a las 3 deseadas y ajustamos IDs y Cortes (sls) equitativamente
    rois = {'hip2_left.txt', 'hip2_right.txt', 'ccn.txt'};
    ids  = [1, 2, 3]; 
    sls  = [2, 2, 3]; 
    
    all_data = [];
    
    % Buscamos los archivos .txt de las ROIs
    for r = 1:length(rois)
        busqueda_roi = dir(fullfile('**', rois{r}));
        
        if ~isempty(busqueda_roi)
            ruta_real_roi = fullfile(busqueda_roi(1).folder, busqueda_roi(1).name);
            
            % readmatrix se salta el texto de la cabecera automáticamente
            c = readmatrix(ruta_real_roi); 
            
            % Limpieza de filas vacías o con NaN
            c(any(isnan(c), 2), :) = [];
            
            if isempty(c), continue; end
            
            s = sls(r);
            vals_roi = zeros(size(c,1), 11); 
            for row = 1:size(c,1)
                cx = c(row,1) + 1; 
                cy = c(row,2) + 1;
                
                vals_roi(row,:) = [ids(r), c(row,1), c(row,2), ...
                                   di_m(cx, cy, s), de_m(cx, cy, s), ...
                                   f_m(cx, cy, s),  tex_m(cx, cy, s), ...
                                   0, 0, 0, 0]; 
            end
            all_data = [all_data; vals_roi];
        end
    end
    
    % Guardado de datos final
    if ~isempty(all_data)
        nombre_out = sprintf('%s_NEXI_Data.txt', nombre_raton);
        writematrix(all_data, fullfile(ruta_destino, nombre_out));
        fprintf('Procesado con éxito: %s\n', nombre_raton);
    end
end

fprintf('\n--- FIN DEL PROCESADO NEXI ---\n');
