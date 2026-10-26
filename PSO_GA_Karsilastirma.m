
clc;
clear;
close all;

%% 1. PROBLEM TANIMI

baslangic = [10 10];
hedef = [90 90];

engeller = [
    30 30 10;
    50 50 12;
    70 30 10;
    30 70 10;
    70 70 10
];

guvenlik = 2;
cezaKatsayisi = 1000;

nVar = 10;
lb = zeros(1,nVar);
ub = 100*ones(1,nVar);

fitness = @(X) yolMaliyeti(X,baslangic,hedef, ...
    engeller,guvenlik,cezaKatsayisi);

% Grafik ayarlari
set(groot,'defaultAxesColor','w');
set(groot,'defaultAxesXColor','k');
set(groot,'defaultAxesYColor','k');
set(groot,'defaultTextColor','k');

%% 2. DENEY AYARLARI

deneySayisi = 10;

psoJ = zeros(deneySayisi,1);
gaJ = zeros(deneySayisi,1);

psoL = zeros(deneySayisi,1);
gaL = zeros(deneySayisi,1);

psoSure = zeros(deneySayisi,1);
gaSure = zeros(deneySayisi,1);

psoGuvenli = false(deneySayisi,1);
gaGuvenli = false(deneySayisi,1);

% En iyi guvenli rotalari saklama
enIyiPSO = [];
enIyiGA = [];

enIyiPSOUzunluk = inf;
enIyiGAUzunluk = inf;

psoOptions = optimoptions('particleswarm', ...
    'SwarmSize',40, ...
    'MaxIterations',100, ...
    'Display','off');

gaOptions = optimoptions('ga', ...
    'PopulationSize',40, ...
    'MaxGenerations',100, ...
    'Display','off');

%% 3. PSO VE GA COKLU DENEYLERI

for k = 1:deneySayisi

    fprintf('Deney %d / %d\n',k,deneySayisi);

    % PSO
    rng(100+k);

    tic;
    [Xpso,psoJ(k)] = particleswarm( ...
        fitness,nVar,lb,ub,psoOptions);
    psoSure(k) = toc;

    [~,Cpso,psoL(k)] = yolMaliyeti( ...
        Xpso,baslangic,hedef,engeller, ...
        guvenlik,cezaKatsayisi);

    psoGuvenli(k) = Cpso < 1e-8;

    % En iyi guvenli PSO rotasi
    if psoGuvenli(k) && ...
            psoL(k) < enIyiPSOUzunluk

        enIyiPSOUzunluk = psoL(k);

        enIyiPSO = [baslangic; ...
            reshape(Xpso,2,[])'; hedef];
    end

    % GA
    rng(100+k);

    tic;
    [Xga,gaJ(k)] = ga( ...
        fitness,nVar,[],[],[],[], ...
        lb,ub,[],gaOptions);
    gaSure(k) = toc;

    [~,Cga,gaL(k)] = yolMaliyeti( ...
        Xga,baslangic,hedef,engeller, ...
        guvenlik,cezaKatsayisi);

    gaGuvenli(k) = Cga < 1e-8;

    % En iyi guvenli GA rotasi
    if gaGuvenli(k) && ...
            gaL(k) < enIyiGAUzunluk

        enIyiGAUzunluk = gaL(k);

        enIyiGA = [baslangic; ...
            reshape(Xga,2,[])'; hedef];
    end

end

%% 4. SONUC TABLOSU

sonuclar = table( ...
    (1:deneySayisi)', ...
    psoL,gaL,psoJ,gaJ, ...
    psoSure,gaSure, ...
    psoGuvenli,gaGuvenli, ...
    'VariableNames', { ...
    'Deney','PSO_Yol','GA_Yol', ...
    'PSO_Maliyet','GA_Maliyet', ...
    'PSO_Sure','GA_Sure', ...
    'PSO_Guvenli','GA_Guvenli'});

disp(sonuclar);

fprintf('\n===== ISTATISTIKSEL SONUCLAR =====\n');

fprintf('PSO ortalama maliyet: %.4f\n',mean(psoJ));
fprintf('GA ortalama maliyet: %.4f\n',mean(gaJ));

fprintf('PSO en iyi maliyet: %.4f\n',min(psoJ));
fprintf('GA en iyi maliyet: %.4f\n',min(gaJ));

fprintf('PSO standart sapma: %.4f\n',std(psoJ));
fprintf('GA standart sapma: %.4f\n',std(gaJ));

fprintf('PSO ortalama sure: %.4f sn\n',mean(psoSure));
fprintf('GA ortalama sure: %.4f sn\n',mean(gaSure));

fprintf('PSO guvenli cozum orani: %.1f%%\n', ...
    100*mean(psoGuvenli));

fprintf('GA guvenli cozum orani: %.1f%%\n', ...
    100*mean(gaGuvenli));

%% 5. GUVENLI YOL ANALIZI

psoGuvenliYollar = psoL(psoGuvenli);
gaGuvenliYollar = gaL(gaGuvenli);

fprintf('\n===== GUVENLI YOL ANALIZI =====\n');

fprintf('PSO guvenli yol sayisi: %d\n', ...
    numel(psoGuvenliYollar));

fprintf('GA guvenli yol sayisi: %d\n', ...
    numel(gaGuvenliYollar));

if ~isempty(psoGuvenliYollar)
    fprintf('PSO guvenli ortalama yol: %.4f\n', ...
        mean(psoGuvenliYollar));

    fprintf('PSO en kisa guvenli yol: %.4f\n', ...
        min(psoGuvenliYollar));
end

if ~isempty(gaGuvenliYollar)
    fprintf('GA guvenli ortalama yol: %.4f\n', ...
        mean(gaGuvenliYollar));

    fprintf('GA en kisa guvenli yol: %.4f\n', ...
        min(gaGuvenliYollar));
end

%% 6. PSO ROTASI - AYRI HARITA

if ~isempty(enIyiPSO)

    figure('Color','w');
    hold on;

    engelCiz(engeller,guvenlik);

    plot(enIyiPSO(:,1),enIyiPSO(:,2), ...
        'b-o','LineWidth',2, ...
        'MarkerSize',5, ...
        'DisplayName','PSO Yolu');

    noktaCiz(baslangic,hedef);

    title(sprintf( ...
        'PSO En Iyi Guvenli Rota - L = %.2f', ...
        enIyiPSOUzunluk));

    haritaAyarla();

    exportgraphics(gcf,'01_PSO_Rotasi.png', ...
        'Resolution',300);

    hold off;
end

%% 7. GA ROTASI - AYRI HARITA

if ~isempty(enIyiGA)

    figure('Color','w');
    hold on;

    engelCiz(engeller,guvenlik);

    plot(enIyiGA(:,1),enIyiGA(:,2), ...
        'm-s','LineWidth',2, ...
        'MarkerSize',5, ...
        'DisplayName','GA Yolu');

    noktaCiz(baslangic,hedef);

    title(sprintf( ...
        'GA En Iyi Guvenli Rota - L = %.2f', ...
        enIyiGAUzunluk));

    haritaAyarla();

    exportgraphics(gcf,'02_GA_Rotasi.png', ...
        'Resolution',300);

    hold off;
end

%% 8. PSO VE GA AYNI HARITADA

figure('Color','w');
hold on;

engelCiz(engeller,guvenlik);

if ~isempty(enIyiPSO)
    plot(enIyiPSO(:,1),enIyiPSO(:,2), ...
        'b-o','LineWidth',2, ...
        'DisplayName',sprintf( ...
        'PSO (L=%.2f)',enIyiPSOUzunluk));
end

if ~isempty(enIyiGA)
    plot(enIyiGA(:,1),enIyiGA(:,2), ...
        'm-s','LineWidth',2, ...
        'DisplayName',sprintf( ...
        'GA (L=%.2f)',enIyiGAUzunluk));
end

noktaCiz(baslangic,hedef);

title('PSO ve GA En Iyi Guvenli Rota Karsilastirmasi');

haritaAyarla();

exportgraphics(gcf,'03_PSO_GA_Ortak_Harita.png', ...
    'Resolution',300);

hold off;

%% 9. GUVENLI YOL UZUNLUGU GRAFIGI

figure('Color','w');

ortalamalar = [NaN NaN];

if ~isempty(psoGuvenliYollar)
    ortalamalar(1) = mean(psoGuvenliYollar);
end

if ~isempty(gaGuvenliYollar)
    ortalamalar(2) = mean(gaGuvenliYollar);
end

bar(ortalamalar);

set(gca,'XTick',1:2, ...
    'XTickLabel',{'PSO','GA'});

ylabel('Ortalama Yol Uzunlugu');
title('Guvenli Cozumlerin Ortalama Yol Uzunlugu');
grid on;

exportgraphics(gcf,'04_Guvenli_Yol.png', ...
    'Resolution',300);

%% 10. PERFORMANS KARSILASTIRMASI

figure('Color','w');

subplot(2,2,1);

plot(1:deneySayisi,psoJ, ...
    'b-o','LineWidth',1.5);
hold on;

plot(1:deneySayisi,gaJ, ...
    'r-s','LineWidth',1.5);

xlabel('Deney Numarasi');
ylabel('Amac Fonksiyonu');
title('Deneylere Gore Maliyet');
legend('PSO','GA','Location','best');
grid on;

subplot(2,2,2);

bar([mean(psoJ),mean(gaJ)]);

set(gca,'XTick',1:2, ...
    'XTickLabel',{'PSO','GA'});

ylabel('Ortalama Maliyet');
title('Ortalama Amac Fonksiyonu');
grid on;

subplot(2,2,3);

bar([mean(psoSure),mean(gaSure)]);

set(gca,'XTick',1:2, ...
    'XTickLabel',{'PSO','GA'});

ylabel('Sure (saniye)');
title('Ortalama Hesaplama Suresi');
grid on;

subplot(2,2,4);

bar([100*mean(psoGuvenli), ...
    100*mean(gaGuvenli)]);

set(gca,'XTick',1:2, ...
    'XTickLabel',{'PSO','GA'});

ylabel('Guvenli Cozum Orani (%)');
ylim([0 100]);
title('Guvenlik Karsilastirmasi');
grid on;

sgtitle('PSO ve GA Performans Karsilastirmasi');

exportgraphics(gcf,'05_Performans.png', ...
    'Resolution',300);

%% 11. SONUCLARI KAYDET

writetable(sonuclar,'PSO_GA_sonuclar.xlsx');

fprintf('\n===== EN IYI GUVENLI ROTALAR =====\n');

if ~isempty(enIyiPSO)
    fprintf('PSO en iyi guvenli yol: %.4f\n', ...
        enIyiPSOUzunluk);
    disp(enIyiPSO);
else
    fprintf('PSO guvenli rota bulunamadi.\n');
end

if ~isempty(enIyiGA)
    fprintf('GA en iyi guvenli yol: %.4f\n', ...
        enIyiGAUzunluk);
    disp(enIyiGA);
else
    fprintf('GA guvenli rota bulunamadi.\n');
end

fprintf('\nTum grafikler ve Excel kaydedildi.\n');

%% 12. YEREL FONKSIYONLAR

function [J,C,L] = yolMaliyeti(X,baslangic,hedef, ...
    engeller,guvenlik,cezaKatsayisi)

    araNoktalar = reshape(X,2,[])';
    yol = [baslangic;araNoktalar;hedef];

    L = sum(sqrt(sum(diff(yol).^2,2)));

    C = 0;

    for i = 1:size(yol,1)-1

        A = yol(i,:);
        B = yol(i+1,:);
        AB = B-A;

        for j = 1:size(engeller,1)

            merkez = engeller(j,1:2);
            r = engeller(j,3)+guvenlik;

            t = dot(merkez-A,AB) / ...
                max(dot(AB,AB),eps);

            t = max(0,min(1,t));

            enYakin = A+t*AB;
            mesafe = norm(merkez-enYakin);

            ihlal = max(0,r-mesafe);
            C = C+ihlal^2;
        end
    end

    J = L+cezaKatsayisi*C;
end

function engelCiz(engeller,guvenlik)

    theta = linspace(0,2*pi,200);

    for i = 1:size(engeller,1)

        x = engeller(i,1);
        y = engeller(i,2);
        r = engeller(i,3);

        fill(x+r*cos(theta), ...
            y+r*sin(theta), ...
            [0.7 0.1 0.1], ...
            'FaceAlpha',0.5, ...
            'HandleVisibility','off');

        plot(x+(r+guvenlik)*cos(theta), ...
            y+(r+guvenlik)*sin(theta), ...
            'r--','LineWidth',1, ...
            'HandleVisibility','off');
    end
end

function noktaCiz(baslangic,hedef)

    plot(baslangic(1),baslangic(2), ...
        'go','MarkerFaceColor','g', ...
        'MarkerSize',9, ...
        'DisplayName','Baslangic');

    plot(hedef(1),hedef(2), ...
        'ko','MarkerFaceColor','k', ...
        'MarkerSize',9, ...
        'DisplayName','Hedef');
end

function haritaAyarla()

    xlim([0 100]);
    ylim([0 100]);

    axis equal;
    grid on;

    xlabel('X Konumu');
    ylabel('Y Konumu');

    legend('Location','best');
end
