clear all
close all
tic

%%% SHAPE
%%%
%%% 0 = Uniform
%%% 1 = GratingX
%%% 2 = GratingY
%%% 3 = GratingXY
%%% 4 = Triangle
%%% 5 = Circle
%%% 6 = Rough
%%% 7 = Real surface, only 512x512, 10x10 or 30umx30um

% LayerObjects
% n=["MgF2", "ZnS", "AlInP", "GaAs", "InGaP", "Al03GaAs", "Ag"];
% shape=[0, 0, 0, 0, 0, 0, 0];
% roughdim=[0, 0, 0, 0, 0, 0, 0];
% L=[94, 44, 20, 300, 100, 100, 100];

n           = ["InGaP","Al03GaAs","InGaP","GaP","Ag","Ag"];
shape       = [0,0,0,0,7,0];
roughdim	= [0,0,0,0,0,0];
L           = [125,50,50,larray(j),3000];

roughness = 1;

lab1 = 459;
lab2 = 966;
dlab = 1;
lam0_r = lab1:dlab:lab2;

eps_lab = get_lab(lam0_r);

wb = waitbar(0,'Please wait...');

theta	= 82/360*2*pi;%pi/4;
phi     = 0;
pte     = 0.5;
ptm     = 0.5;
% rscale = 4;
% Xresolution = 10;
% Yresolution = 10;
labda_x = 30000;%1280*rscale;%120;
labda_y = 30000;%1280*rscale;%120;
lenx    = 512;%labda_x/Xresolution;
leny    = 512;%labda_y/Yresolution;
P       = 9;
Q       = 9;
num_H   = P*Q;

for iter=1:length(lam0_r)
    toc_start=toc;
    k_0 = 2*pi./lam0_r(iter);
    
    [eps_r,mu_r] = build_perm(n,shape,lenx,leny,P,Q,eps_lab,iter,roughdim,roughness);
    [Kx,Ky,Kz,beta] = calc_K(k_0,theta,phi,eps_r,mu_r,P,Q,labda_x,labda_y);
    
    s_inc=get_sinc(k_0,eps_r{1},mu_r{1},phi,theta,pte,ptm,num_H);
    
    [r,t,J_im] = calc_layers_transmittance(num_H,mu_r,eps_r,Kx,Ky,Kz,k_0,s_inc,L,shape,roughdim);
    J(iter,:)=[J_im{:}];
    
    r{3} = -inv(Kz{1})*(Kx*r{1}+Ky*r{2});
    t{3} = -inv(Kz{end})*(Kx*t{1}+Ky*t{2});

    [Rtot(iter),R] = get_power(r,mu_r{1},mu_r{1},Kz{1},beta(3)/k_0);
    [Ttot(iter),T] = get_power(t,mu_r{end},mu_r{1},Kz{end},beta(3)/k_0);
    haze(iter) = (sum(R)-R((num_H+1)/2))/sum(R);
    
    toc_arr(iter)=(toc-toc_start);
    timeleft=duration(seconds((length(lam0_r)-iter)*mean(toc_arr)));
    waitbar(iter/length(lam0_r),wb,'Time remaining: ' + string(timeleft,'hh:mm:ss') )
end

toc
delete(wb)

% figure
% [Er,Eth,Eph]=plot_field({reshape(r{1},P,Q),reshape(r{2},P,Q),reshape(r{3},P,Q)},beta,labda_x,labda_y,lenx,leny,P,Q);

% plot_harmonics(Kx,Ky,Kz{1},R,true)

%h(1) = plot_results(lam0_r,n,shape,J,Rtot,Ttot);
%h(2) = figure;
plot(lam0_r,Rtot)
hold on
Rfftj(j)=lam0_r(Rtot==min(Rtot));
%plot(lam0_r,haze)

%save("haze650ref.mat","haze")
%filename="scale4harmonics9roughness"+roughness+".fig";
%savefig(h,filename)
%close(h)
end
figure
plot(larray,Rfftj)