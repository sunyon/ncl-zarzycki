;========================================================
; This file reads in a traj file produced by the TC tracker
; and produces a lat-lon plot of trajectories color-coded by intensity
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "/glade/u/home/zarzycki/ncl/functions/getTrajectoriesGeneric.ncl"
load "strip_missing.ncl"
load "find_landfalls.ncl"

;========================================================
begin


;===========================================================================================


thefile="ibtracs-1979-2012-NATL_only.txt"
thefile="/glade/u/home/zarzycki/tempest-scripts/asd-se/trajectories.txt.NE30"
ncols = 10                    ; assign number of columns
maxLines = -1
headerDelimStr = "start"
delimStr="tab"
isHeader=False
traj_data = getTrajectories(thefile,ncols,maxLines,headerDelimStr,delimStr,isHeader)

lon = traj_data(:,1,:)
lat = traj_data(:,2,:)
wind = traj_data(:,4,:)*0.85
pres = traj_data(:,3,:)/100.
yyyy=  traj_data(:,6,:)
mm= traj_data(:,7,:)
dd= traj_data(:,8,:)
hh= traj_data(:,9,:)

print("mean lat: "+avg(lat))

ndims = dimsizes(lon)
nstorms = ndims(0)
ntimes = ndims(1)


;===========================================================================================

npossLF=5

landfall_lat=new((/npossLF,nstorms/),typeof(lat))
landfall_lon=new((/npossLF,nstorms/),typeof(lon))
landfall_wind=new((/npossLF,nstorms/),typeof(wind))
landfall_pres=new((/npossLF,nstorms/),typeof(pres))

;===========================================================================================

hrsbase=6
hrsinterp=1

print("max number of time records in orig data: "+ntimes)
ntimesinterp = ( (ntimes-1) * toint(hrsbase)/toint(hrsinterp) ) + 1
print("max number of time records in interpolated data: "+ntimesinterp)

;interp_lat=new((/nstorms,ntimesinterp/),typeof(lat))
;interp_lon=new((/nstorms,ntimesinterp/),typeof(lon))
;interp_wind=new((/nstorms,ntimesinterp/),typeof(wind))
;interp_pres=new((/nstorms,ntimesinterp/),typeof(pres))

xi = ispan(0,(ntimes-1)*toint(hrsbase)        , hrsbase  )
xo = ispan(0,(ntimesinterp-1)*toint(hrsinterp), hrsinterp)

interp_lat =linint1_n_Wrap(xi,lat,False,xo,0,1) 
interp_lon =linint1_n_Wrap(xi,lon,False,xo,0,1) 
interp_wind=linint1_n_Wrap(xi,wind,False,xo,0,1) 
interp_pres=linint1_n_Wrap(xi,pres,False,xo,0,1) 

;===========================================================================================

; find landfalls

;stormtest=49

debug=False


STIX=0
ENIX=nstorms-1
if (debug) then
  STIX=20
  ENIX=20
end if

do ii = STIX,ENIX
  print("STORM NUMBER: "+ii)

  latClean=strip_missing(interp_lat(ii,:))
  lonClean=strip_missing(interp_lon(ii,:))

  IX = find_landfalls(latClean,lonClean,1,12,0.75,npossLF,debug)

  do zz = 0,npossLF-1
    if(.not.ismissing(IX(zz)))
      landfall_lat(zz,ii) = interp_lat(ii,IX(zz))
      landfall_lon(zz,ii) = interp_lon(ii,IX(zz))
      landfall_wind(zz,ii) = interp_wind(ii,IX(zz))
      landfall_pres(zz,ii) = interp_pres(ii,IX(zz))
    end if
  end do

  if (debug) then
    print("       ")
    print(landfall_lat(:,ii)+" "+landfall_lon(:,ii))
  end if

  delete(latClean)
  delete(lonClean)

end do

print(num(landfall_lat(0,:)))

;===========================================================================================


;--------------------------------------------------------
print("Beginning plot sequence")
wks  = gsn_open_wks("x11","landfall."+thefile)
map = new(1,graphic)
  
res  = True
res@gsnDraw    = False
res@gsnFrame   = False
res@gsnMaximize = True
res@mpFillOn             = True              ; turn off gray continents
res@mpLandFillColor = "Tan"
res@mpOceanFillColor = "LightBlue1"
res@mpOutlineOn = True
res@mpInlandWaterFillColor = res@mpOceanFillColor
res@mpGreatCircleLinesOn = True
  
res@mpMinLatF             = 5
res@mpMaxLatF             = 45
res@mpMinLonF             = 260
res@mpMaxLonF             = 310

 
map = gsn_csm_map_ce(wks,res)

gsn_define_colormap(wks,"rainbow+white+gray")
  polyres               = True          ; poly marker mods desired 
  polyres@gsMarkerIndex = 1            ; choose circle as polymarker
  lineres = True
  
dum = new((/npossLF,nstorms/),graphic)
dum1 = new((/npossLF,nstorms/),graphic)

do j = 0,nstorms-1
do i = 0,npossLF-1

thisWind=landfall_wind(i,j)
thisLat=landfall_lat(i,j)
thisLon=landfall_lon(i,j)

if (.not.ismissing(thisWind))


  linethicknesses = (/0.5,1.0,1.3,1.9,2.3,2.6/)
  linethicknesses = 4.0*linethicknesses

  polyres@gsMarkerSizeF = 0.03           ; select size to avoid streaking
  if (thisWind .lt. 17)
    polyres@gsMarkerColor = (/"blue"/)
    lineres@gsLineColor = (/"blue"/)
    lineres@gsLineThicknessF = linethicknesses(0)
  else if (thisWind .ge. 17 .and. thisWind .lt. 33)
    polyres@gsMarkerColor = (/"green3"/)
    lineres@gsLineColor = (/"green3"/)
    lineres@gsLineThicknessF = linethicknesses(1)
  else if (thisWind .ge. 33 .and. thisWind .lt. 43)
    polyres@gsMarkerColor = (/"yellow2"/)
    lineres@gsLineColor = (/"yellow2"/)
    lineres@gsLineThicknessF = linethicknesses(2)
  else if (thisWind .ge. 43 .and. thisWind .lt. 49)
    polyres@gsMarkerColor = (/"orange"/)
    lineres@gsLineColor = (/"orange"/)
    lineres@gsLineThicknessF = linethicknesses(3)
  else if (thisWind .ge. 49 .and. thisWind .lt. 58)
    polyres@gsMarkerColor = (/"darkorange3"/)
    lineres@gsLineColor = (/"darkorange3"/)
    lineres@gsLineThicknessF  = linethicknesses(4)
  else
    polyres@gsMarkerColor = (/"red"/) 
    lineres@gsLineColor = (/"red"/)
    lineres@gsLineThicknessF  = linethicknesses(5)
  end if
  end if
  end if
  end if
  end if
  
 txres               = True                            
 txres@txFontHeightF = 0.01             ; Set the font height
 
 polyresback=polyres
 polyresback@gsMarkerSizeF=0.045
 polyresback@gsMarkerColor="black" 

      dum1(i,j) = gsn_add_polymarker(wks,map,thisLon,thisLat,polyresback)
      dum(i,j) = gsn_add_polymarker(wks,map,thisLon,thisLat,polyres)
  
end if

end do
end do
  
print("Drawing plot")

resP = True
resP@amJust           = "TopRight"
resP@gsnPanelFigureStringsFontHeightF = 0.027
gsn_panel(wks,map,(/1,1/),resP)             ; now draw as one plot

end


exit



















































;===========================================================================================


print("Beginning plot sequence")
wks  = gsn_open_wks("x11","trajs."+thefile)
map = new(1,graphic)
  
res  = True
res@gsnDraw    = False
res@gsnFrame   = False
res@gsnMaximize = True
res@mpFillOn             = True              ; turn off gray continents
res@mpLandFillColor = "Tan"
res@mpOceanFillColor = "LightBlue1"
res@mpOutlineOn = True
res@mpInlandWaterFillColor = res@mpOceanFillColor
res@mpGreatCircleLinesOn = True
 
res@mpMinLatF             = 5
res@mpMaxLatF             = 45
res@mpMinLonF             = 260
res@mpMaxLonF             = 355
 
map = gsn_csm_map_ce(wks,res)

gsn_define_colormap(wks,"rainbow+white+gray")
  polyres               = True          ; poly marker mods desired 
  polyres@gsMarkerIndex = 1            ; choose circle as polymarker
  lineres = True
  
dum = new((/nstorms,ntimesinterp/),graphic)

do i = STIX,ENIX
do j = 0,ntimesinterp-1

thisWind=interp_wind(i,j)


  linethicknesses = (/0.5,1.0,1.3,1.9,2.3,2.6/)
  linethicknesses = 4.0*linethicknesses

if (.not.ismissing(thisWind))

;  polyres@gsMarkerSizeF = 2.0           ; select size to avoid streaking
  if (thisWind .lt. 17)
    polyres@gsMarkerColor = (/"blue"/)
    lineres@gsLineColor = (/"blue"/)
    lineres@gsLineThicknessF = linethicknesses(0)
  else if (thisWind .ge. 17 .and. thisWind .lt. 33)
    polyres@gsMarkerColor = (/"green3"/)
    lineres@gsLineColor = (/"green3"/)
    lineres@gsLineThicknessF = linethicknesses(1)
  else if (thisWind .ge. 33 .and. thisWind .lt. 43)
    polyres@gsMarkerColor = (/"yellow2"/)
    lineres@gsLineColor = (/"yellow2"/)
    lineres@gsLineThicknessF = linethicknesses(2)
  else if (thisWind .ge. 43 .and. thisWind .lt. 49)
    polyres@gsMarkerColor = (/"orange"/)
    lineres@gsLineColor = (/"orange"/)
    lineres@gsLineThicknessF = linethicknesses(3)
  else if (thisWind .ge. 49 .and. thisWind .lt. 58)
    polyres@gsMarkerColor = (/"darkorange3"/)
    lineres@gsLineColor = (/"darkorange3"/)
    lineres@gsLineThicknessF  = linethicknesses(4)
  else
    polyres@gsMarkerColor = (/"red"/) 
    lineres@gsLineColor = (/"red"/)
    lineres@gsLineThicknessF  = linethicknesses(5)
  end if
  end if
  end if
  end if
  end if
  
 txres               = True                            
 txres@txFontHeightF = 0.01             ; Set the font height
  
if (j .ne. 0) then
    dum(i,j) = gsn_add_polyline(wks,map,(/interp_lon(i,j),interp_lon(i,j-1)/),(/interp_lat(i,j),interp_lat(i,j-1)/),lineres)
end if
  
end if

end do
end do

print("Drawing plot")

resP = True
resP@amJust           = "TopRight"
resP@gsnPanelFigureStringsFontHeightF = 0.027
gsn_panel(wks,map,(/1,1/),resP)             ; now draw as one plot

end