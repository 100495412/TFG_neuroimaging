clear all; close all;

% --- CONFIGURACIÓN DE RUTAS ---
ruta_base = 'S:\mdnovalbos\info_services\blizarbe_lab_share\TFG Lola\NEXI\Diffusion_times';
ruta_res_base = 'S:\mdnovalbos\info_services\blizarbe_lab_share\TFG Lola\Resultados_filtrados';
ruta_funciones = 'S:\mdnovalbos\info_services\blizarbe_lab_share\TFG Lola\Funciones';
addpath(genpath('S:\mdnovalbos\info_services\blizarbe_lab_share\TFG Lola\Funciones\NIfTI_toolbox'));

% --- DEFINICIÓN DE TIEMPOS ---
tiempos = {'DKI_1_1','DKI_2_1','DKI_3_1','DKI_4_1'};

fprintf('--- INICIANDO PROCESADO DKI (CON ROIs DINÁMICAS + CUERPO CALLOSO) ---\n\n');

lista_ratones = struct('name', 'R87', 'isdir', true);

for i = 1:length(lista_ratones)
    nombre_raton = lista_ratones(i).name;
    fprintf('--- Ratón: %s ---\n', nombre_raton);
    
    % --- Lista de ROIs (Añadido ccn.txt en la posición 8) ---
    rois = {'hip2_left.txt', 'hip2_right.txt', 'hipp_left.txt','hipp_right.txt', ...
            'hyp.txt', 'Nac_left.txt', 'Nac_right.txt', 'ccn.txt'};
    ids  = 1:length(rois); 
    sls  = [2,2,3,3,3,5,5,3]; 
    
    % --- Loop por tiempos ---
    for t = 1:length(tiempos)
        tiempo_act = tiempos{t};
        fprintf('Tiempo: %s\n', tiempo_act);
        
        % =========================
        % 🔴 SELECCIÓN DE ROIs
        % =========================
        if strcmp(nombre_raton, 'R87') && strcmp(tiempo_act, 'DKI_4_1')
            ruta_rois_final = fullfile(ruta_base, nombre_raton, 'derivatives', 'DKI_4_1');
        else
            ruta_rois_final = fullfile(ruta_base, nombre_raton, 'derivatives', 'DKI_1_1');
        end
        fprintf('Usando ROIs de: %s\n', ruta_rois_final);
        
        if ~exist(ruta_rois_final,'dir')
            warning('No existe carpeta de ROIs para %s | %s', nombre_raton, tiempo_act);
            continue;
        end
        
        % --- Cargar ROIs ---
        all_rois_coords = cell(length(rois),1);
        for r = 1:length(rois)
            roi_file = fullfile(ruta_rois_final, rois{r});
            if exist(roi_file,'file')
                try
                    c = readmatrix(roi_file);
                    all_rois_coords{r} = c;
                catch
                    warning('No se pudo leer ROI: %s', rois{r});
                    all_rois_coords{r} = [];
                end
            else
                warning('ROI no encontrado: %s', rois{r});
                all_rois_coords{r} = [];
            end
        end
        
        % --- Carpeta de mapas ---
        ruta_mapas_final = fullfile(ruta_base, nombre_raton, 'derivatives', tiempo_act);
        if ~exist(ruta_mapas_final,'dir')
            warning('No se encontraron mapas para %s | %s', nombre_raton, tiempo_act);
            continue;
        end
        
        % --- Cargar mapas ---
        try
            AD_m   = cargar_mapas_func(ruta_mapas_final, 'ad_dki');
            RD_m   = cargar_mapas_func(ruta_mapas_final, 'rd_dki');
            MD_m   = cargar_mapas_func(ruta_mapas_final, 'md_dki');
            AK_m   = cargar_mapas_func(ruta_mapas_final, 'ak_dki');
            RK_m   = cargar_mapas_func(ruta_mapas_final, 'rk_dki');
            MK_m   = cargar_mapas_func(ruta_mapas_final, 'mk_dki');
            FA_k_m = cargar_mapas_func(ruta_mapas_final, 'fa_dki');
        catch ME
            warning('Error cargando mapas para %s | %s: %s', nombre_raton, tiempo_act, ME.message);
            continue;
        end
        
        % --- Extracción ---
        all_d = [];
        for r = 1:length(rois)
            c = all_rois_coords{r};
            if isempty(c), continue; end
            s = sls(r);
            if s > size(MD_m,3)
                warning('Slice %d no existe en %s | %s', s, nombre_raton, tiempo_act);
                continue;
            end
            
            vals_roi = zeros(size(c,1),10);
            for row = 1:size(c,1)
                cx = c(row,1)+1;
                cy = c(row,2)+1;
                vals_roi(row,:) = [ids(r), c(row,1), c(row,2), ...
                                   MD_m(cx,cy,s)*1000, AD_m(cx,cy,s)*1000, RD_m(cx,cy,s)*1000, ...
                                   AK_m(cx,cy,s), RK_m(cx,cy,s), MK_m(cx,cy,s), FA_k_m(cx,cy,s)];
            end
            all_d = [all_d; vals_roi];
        end
        
        % --- Guardado con Filtrado ---
        if ~isempty(all_d)
            all_f = all_d(all_d(:,5) < 1450, :);
            if ~isempty(all_f)
                ruta_destino_t = fullfile(ruta_res_base, tiempo_act);
                if ~exist(ruta_destino_t, 'dir'), mkdir(ruta_destino_t); end
                
                nombre_out = sprintf('%s_%s_Filtered.txt', nombre_raton, tiempo_act);
                writematrix(all_f, fullfile(ruta_destino_t, nombre_out));
                fprintf('✅ Procesado: %s | %s (Añadido CC)\n', nombre_raton, tiempo_act);
            end
        end
    end
end

fprintf('\n--- FIN DEL PROCESADO DKI ---\n');

% --------------------------
% Función auxiliar
% --------------------------
function img = cargar_mapas_func(ruta_mapas, patron)
    f = dir(fullfile(ruta_mapas, '*.nii*'));
    idx = find(contains({f.name}, patron), 1);
    if isempty(idx)
        error('Archivo NIfTI no encontrado: %s', patron);
    end
    nii = load_nii(fullfile(ruta_mapas, f(idx).name));
    img = flip(permute(nii.img, [1 3 2]), 2);
end