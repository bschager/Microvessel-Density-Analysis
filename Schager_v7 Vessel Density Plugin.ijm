/////////////////////////////Written for FIJI (ImageJ 1.52e)/////////////////////////////////////////////////////
//Default location for classifiers to be saved is the parent directory of the image-containing folder
// see lines 1519 and 1520


//run Schager Save ROIs for vessel density plugin.ijm on folder containing images before running this program.
//run Schager Subsection Density Analysis.ijm after this program if interested in variability in vessel density within images

//Various Variables for calculations
var xpointarray=newArray(); 			//x coordinates for each black skeletonized pixel
var ypointarray=newArray();				//y coordinates for each black skeletonized pixel
var xendpointarray=newArray(); 			//x coordinates for each black skeletonized pixel meeting criteria as an endpoint
var yendpointarray=newArray();			//y coordinates for each black skeletonized pixel meeting criteria as an endpoint
var marray=newArray();					//slope of black skeletonized pixel meeting criteria as an endpoint
var barray=newArray();					//y-intercept of perpendicular line at each black skeletonized pixel
var touchingpixels=newArray();			//<3 means intersection (usually), 2 means endpoint
var anglearray=newArray();				//array containing the angle of the local linear best fit line, in radians
var pointarray=newArray();
var linelengths=newArray();
var doneEnds=newArray();
var upperbound=0;
var lowerbound=0;	
var subtractedlength=0;
var rat=0;
var junctioncount=0;
var junctioncount2=0;
var slice=0;
var allBeads=0;
var restrictedBeads=0;
var FWHM=0;
var numslices=0;
//////////////////////////////////////////////////////////////////////////////////
//Variables holding final table info
var fileName=newArray();
var fileDensity=newArray();
var fileROIVolume=newArray();
var fileVesselLength=newArray();
var fileAverageLength=newArray();
var filePercentVolume=newArray();
var filePercentArea=newArray();
var fileAverageWidth=newArray();
var fileMeanTortuosity=newArray();
var fileMedianTortuosity=newArray();
var fileNumberSlices=newArray();
var fileSlicesSampled=newArray();
var fileTissueThickness=newArray();
var fileROIArea=newArray();
var fileVesselArea=newArray();
var fileVesselVolume=newArray();
var fileCapillaryNumber=newArray();
var fileSignalRatio=newArray();
var fileFWHM=newArray();
var fileAllBeads=newArray();
var fileRestrictedBeads=newArray();

//////////////////////////////////////////////////////////////////////////////////
function myTableAll(a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t){
	title1="Vessel Density";
	title2="["+title1+"]";
	if (isOpen(title1)){
   		print(title2, a+"\t"+b+"\t"+c+"\t"+d+"\t"+e+"\t"+f+"\t"+g+"\t"+h+"\t"+i+"\t"+j+"\t"+k+"\t"+l+"\t"+m+"\t"+n+"\t"+o+"\t"+p+"\t"+q+"\t"+r+"\t"+s+"\t"+t);
	}
	else{
   		run("Table...", "name="+title2+" width=300 height=200");
   		print(title2, "\\Headings:File\tVessel Density (m/mm3)\tROI Volume\tTotal All Vessel Length (m)\tAverage vessel length (um)\t%Volume\t%Area\tAverage Width (um)\tMean Tortuosity (Arc-chord ratio)\tMedian Tortuosity (Arc-chord ratio)\tTotal # Slices\t# Sampled Slices\tTissue Thickness (um)\tROI Area (mm2)\tVessel Area (mm2)\tVessel Volume (mm3)\tCapillary number\tZ Axis FWHM\tAll Maxima\tMaxima in Projection");
   		print(title2, a+"\t"+b+"\t"+c+"\t"+d+"\t"+e+"\t"+f+"\t"+g+"\t"+h+"\t"+i+"\t"+j+"\t"+k+"\t"+l+"\t"+m+"\t"+n+"\t"+o+"\t"+p+"\t"+q+"\t"+r+"\t"+s+"\t"+t);
	}
}

//////////////////////////////////////////////////////////////////////////////////
function params(){
	bground=newArray(3);
	bground[0]="Mixed";
	bground[1]="Always";
	bground[2]="Never";
	Dialog.create("Define Variables for Vessel Density Calculation");
	Dialog.addMessage("note 1: This program is designed for 10x confocal images with 1 zoom.");
	Dialog.addMessage("note 2: It requires Weka Trainable Segmentation Plugin to run.");
	Dialog.addMessage("note 3: If you have not already made ROIs, whole image will be used.");
	Dialog.addMessage("Please input your imaging parameters.");
	Dialog.addNumber("Pixel Size", 1.242, 3, 5, "um");
	Dialog.addNumber("Z-step Size", 4.0, 1, 4, "um");
	Dialog.addNumber("Slice thickness", 50, 0, 3, "um");
	Dialog.addNumber("Slices to Max Project", 8);
	Dialog.addMessage("Projects middle __ slices to determine vessel density");
	Dialog.addMessage("(Enter a number larger than total Slice number to project all)");
	Dialog.addChoice("Background included in file?", bground, bground[0]);
	Dialog.addCheckbox("Batch Process?",  false);
	Dialog.addCheckbox("Save Table to File After Running?",  false);
	Dialog.addMessage("Do not change parameters below unless you know what you are doing");
	Dialog.addNumber("End-joining Box Size (pixels)", 50);
	Dialog.addNumber("Default Background Multiplication Factor", 1);
	Dialog.addNumber("Connect end distance limit", 12, 0, 2, "um");
	Dialog.addNumber("Pixels from endpoint to get line equation", 10);
	Dialog.addNumber("Acceptable angle difference between lines (degrees)", 60);
	Dialog.addNumber("Min Length considered for Average Length", 15, 0,2,"um");
	Dialog.addMessage("Experimentally, correction factor is approximately 1.12.");
	Dialog.addMessage("If you have hand-counted training data, input other correction factor.");
	Dialog.addNumber("Correction Factor (1+% underestimation of hand-counted length)",1);
	Dialog.addNumber("Segment length cutoff for tortuosity", 40,1,3,"um");
	Dialog.addMessage("If not using 8 middle slices of 50 micron sections for density, I recommend");
	Dialog.addMessage("calculating it using area and total vessel length given in results table.");
	
	Dialog.show();
	pxsz=Dialog.getNumber();
	zsz=Dialog.getNumber();
	slicesz=Dialog.getNumber();
	toprj=Dialog.getNumber();
	bkg=Dialog.getChoice();
	if (bkg=="Mixed"){
		bkg=1;
	}
	else if (bkg=="Always"){
		bkg=2;
	}
	else if (bkg=="Never"){
		bkg=3;
	}
	batch=Dialog.getCheckbox();
	stf=Dialog.getCheckbox();
	jbsz=Dialog.getNumber();
	bmf=Dialog.getNumber();
	endlim=Dialog.getNumber();
	endlim=endlim/pxsz;
	eqlim=Dialog.getNumber();
	anglim=Dialog.getNumber();
	avlenlim=Dialog.getNumber();
	cor2=Dialog.getNumber();
	tc=Dialog.getNumber();
	
	states=newArray();
	states=Array.concat(states,pxsz);	//states[0]
	states=Array.concat(states,zsz);	//states[1]
	states=Array.concat(states,slicesz);	//states[2]
	states=Array.concat(states,toprj);	//states[3]
	states=Array.concat(states,bkg);	//states[4]
	states=Array.concat(states,batch);	//states[5]
	states=Array.concat(states,jbsz);	//states[6] 
	states=Array.concat(states,bmf);	//states[7] 
	states=Array.concat(states,endlim);	//states[8] 
	states=Array.concat(states,eqlim);	//states[9] 
	states=Array.concat(states,anglim);	//states[10]
	states=Array.concat(states,avlenlim);	//states[11]
	states=Array.concat(states,cor2);	//states[12]
	states=Array.concat(states,stf);	//states[13] 
	states=Array.concat(states,tc);	//states[14]
	return states;
}

//////////////////////////////////////////////////////////////////////////////////

function index(a,value){
	for(i=0; i<a.length; i++)
		if (a[i]==value) return i;		
	return -1;
}

/////////////////////////////////////////////////////////////////////////////
//https://imagej.nih.gov/ij/macros/tools/ZProfileTool.txt
//adapted from macro for determining vessel width, creates a measurement of tissue thickness

function FWHM1(){
	values = newArray(nSlices);
	for (z=0; z<nSlices; z++) {
		setSlice(z+1);
		getStatistics(area, mean, min, max, std, histogram);
		values[z] = mean;
	}

	Y=values;
	len=lengthOf(Y);

	X=newArray(len);

	for(i=0;i<len;i++){
		X[i]=i*4;
	}

	Fit.doFit("Gaussian", X, Y);

	r2=Fit.rSquared;
	if(r2<0.9){
		print("Warning: Poor Fit",r2);
	}
	
	Fit.plot();
	
	sigma=Fit.p(3);
	FWHM=abs(2*sqrt(2*log(2))*sigma);
	return FWHM;
}

//////////////////////Counts maxima (fluorescent microspheres)//////////////////////////////////////////

function storeROICentroid(coordinate){
	xarray=newArray();
	yarray=newArray();
	run("Clear Results");
	run("Set Measurements...", "centroid redirect=None decimal=0");
	run("Select None");
	nROIs=roiManager("count");
	run("Analyze Particles...", "size=0-Infinity show=Nothing add slice");
	nROIs2=roiManager("count");
	roiManager("Deselect");
	roiManager("Remove Slice Info");
	j=0;
	for (i=nROIs; i<nROIs2; i++) {
	    roiManager("select", i);
	    roiManager("Measure");
		x=getResult("X",j);
		y=getResult("Y",j);
		j=j+1;
		xarray=Array.concat(xarray,x);
		yarray=Array.concat(yarray,y);
	}
	nROIs3=roiManager("count");
	while (nROIs3>nROIs){
		roiManager("select", nROIs3-1);
		roiManager("Delete");
		nROIs3=roiManager("count");
	}
	if (coordinate==0){
		return xarray;
	}
	if (coordinate==1){
		return yarray;
	}
}

function countMaxima(rsteps)
{
name1=getTitle();
run("Select None");
maxima=newArray(2);	
run("8-bit");
setSlice(nSlices/2-1);
setThreshold(50, 255);
setOption("BlackBackground", false);
run("Convert to Mask", "method=Default background=Dark");
run("Analyze Particles...", "size=20-200 pixel circularity=0.9-1.00 show=Masks stack");
close(name1);
selectWindow("Mask of "+name1);
rename(name1);
run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
nROIs=roiManager("count");
if (nROIs>0){
	if (nROIs==1){
		run("Select All");
		getStatistics(area);
		allarea=area;
		roiManager("Select", 0);
		getStatistics(area);
		roiarea=area;
		if (allarea!=roiarea){
			run("Make Inverse");
			roiManager("Add");
			roiManager("Select", 1);
			setBackgroundColor(0, 0, 0);
			run("Clear", "slice");
		}
	}
	else{	
		roiManager("Select", 1);
		setBackgroundColor(0, 0, 0);
		run("Clear", "slice");
	}
}
setSlice(nSlices/2-1);
X=storeROICentroid(0);
Y=storeROICentroid(1);
pos=newArray(lengthOf(X));
maxima[1]=lengthOf(X);
for (j=0; j<lengthOf(X); j++){
	x=X[j];
	y=Y[j];
	sizes=newArray();
	for (i=1; i<nSlices+1; i++){
		setSlice(i);
		if (getPixel(x,y)==255){
			run("Select None");
			doWand(x, y);
			getRawStatistics(nPixels);
			sizes=Array.concat(sizes,nPixels);
		}
		else{
			sizes=Array.concat(sizes,500);
		}
	}
	Array.getStatistics(sizes,min, max, mean, stdDev);
	pos[j]=index(sizes,min)+1;
}
start=round(((nSlices)-rsteps)/2)+1;
stop=start+(rsteps-1);
counter=0;
for (i=0; i<lengthOf(pos); i++){
	if (pos[i]>start-1 && pos[i]<stop+1){
		counter=counter+1;
	}
}
maxima[0]=counter;
return maxima;
}

//////////////////////////////////////////////////////////////////////////////////

function blackpixelcount(){
	x=0;
	y=0;
	blackpixel=0;
	run("Select All");
	getRawStatistics(nPixels, mean, min, max, std);
	while (y<getHeight()+1){
		if (getPixel(x,y)==max){
			blackpixel=blackpixel+1;
		}	
		else if (getPixel(x,y)==min){
			whitepixel=whitepixel+1;
		}
		if (x==getWidth()){
			y=y+1;
			x=0;
		}
		else {
			x=x+1;
		}
	}
	if (mean<max/2){
		return blackpixel
	}
	else{
		return whitepixel
	}
}

//////////////////////////////////////////////////////////////////////////////////

function backgroundmultiply(factor){
	x=0;
	y=0;
	while (y<getHeight()+1){
		setPixel(x,y,factor*getPixel(x,y));
		if (x==getWidth()){
			y=y+1;
			x=0;
		}
		else {
			x=x+1;
		}
	}
}

function backgroundsubtract(factor){
	x=0;
	y=0;
	while (y<getHeight()+1){
		setPixel(x,y,getPixel(x,y)-factor);
		if (x==getWidth()){
			y=y+1;
			x=0;
		}
		else {
			x=x+1;
		}
	}
}


//////////////////////////////////////////////////////////////////////////////////
//for determining tortuosity
//minimum=cutoff length for determining tortuosity
//p=cutoff length for counting segment number or including 
//status variable determines whether tortuosity, number of segments, or average segment length is calculated
function vesselanalysis(p,minimum,status){
	run("Analyze Skeleton (2D/3D)", "prune=none show");
	IJ.renameResults("Results","GOB");
	IJ.renameResults("Branch information","Results");
	len=0;
	num=0;
	tot=0;
	tort=newArray();
	tortu=newArray(2);
	blen=newArray();
	bleng=newArray(2);
	if (status==2){		//number of segments
		for (i=0; i<nResults; i++){
			if (getResult("Branch length",i)>p)
			{
			tot=tot+1;
			}
		}
	}
	else if (status==1){
		for (i=0; i<nResults; i++){
			if(getResult("Branch length",i)>minimum){
				t=getResult("Branch length",i)/getResult("Euclidean distance",i);
				len=len+t;
				num=num+1;
				tort=Array.concat(tort,t);
			}	
		}
		tort=Array.sort(tort);
		if(lengthOf(tort)%2==1){
			medtort=tort[(lengthOf(tort)/2-0.5)];
		}
		else{
			medtort=(tort[lengthOf(tort)/2]+tort[lengthOf(tort)/2-1])/2;
		}
	}
	else{	//gets internodal segment median length
		for (i=0; i<nResults; i++){
			v1a=toString(getResult("V1 x",i))+","+toString(getResult("V1 y",i));
			v2a=toString(getResult("V2 x",i))+","+toString(getResult("V2 y",i));
			counter1=0;
			counter2=0;
			for (j=i+1; j<nResults; j++){ //if endpoints for segment are also endpoints for other segments, then the segment is internodal
				v1b=toString(getResult("V1 x",j))+","+toString(getResult("V1 y",j));
				v2b=toString(getResult("V2 x",j))+","+toString(getResult("V2 y",j));
				if (v1b==v1a||v1b==v2a){
					counter1=counter1+1;
				}	
				if	(v2b==v1a||v2b==v2a){
					counter2=counter2+1;
				}
			}
			for (j=0; j<i; j++){
				v1b=toString(getResult("V1 x",j))+","+toString(getResult("V1 y",j));
				v2b=toString(getResult("V2 x",j))+","+toString(getResult("V2 y",j));
				if (v1b==v1a||v1b==v2a){
					counter1=counter1+1;
				}	
				if	(v2b==v1a||v2b==v2a){
					counter2=counter2+1;
				}
			}
			if (counter1>0 && counter2>0 && getResult("Branch length",i)>p){
				len=len+getResult("Branch length",i);
				num=num+1;
				blen=Array.concat(blen,getResult("Branch length",i));
			}
		}
		blen=Array.sort(blen);
		if (lengthOf(blen)>0){
			if(lengthOf(blen)%2==1){ //getting middle of array for median measurement
				medblen=blen[(lengthOf(blen)/2-0.5)];
			}
			else{
				medblen=(blen[lengthOf(blen)/2]+blen[lengthOf(blen)/2-1])/2;
			}
		}
		else{
			medblen=0;
		}
	}
	close("Tagged skeleton");
	IJ.renameResults("GOB","Results");
	if (status==1){
		tortu[0]=len/num; //mean tortuosity
		tortu[1]=medtort; //median tortuosity
		return tortu;
	}
	else if (status==2){
		return tot;		//segment number
	}
	else{
		bleng[0]=len/num; //mean internodal length
		bleng[1]=medblen; //median internodal length
		return bleng;
	}
}

//////////////////////////////////////////////////////////////////////////////////

function findEnds(x0,y0,boxwidth){					//Finds endpoints and intersections by storing number of pixels touching in skeleton in a 3x3 grid.
	x=x0;
	y=y0;
	while (y<y0+boxwidth+1){
		if (getPixel(x,y)!=0){
			xpointarray=Array.concat(xpointarray,x);
			ypointarray=Array.concat(ypointarray,y);
			pointarray=Array.concat(pointarray, toString(x)+","+toString(y));
			xpositionarray=newArray();
			ypositionarray=newArray();
			c=x-1;
			u=y-1;
		
			while (u<y+2) {
				if (getPixel(c,u)!=0){
					xpositionarray=Array.concat(xpositionarray, c);
					ypositionarray=Array.concat(ypositionarray, u);
				}
				
				if (c==x+1){
					c=x-1;
					u=u+1;
				}
				else{
					c=c+1;
				}
			}
			if (lengthOf(xpositionarray)==2){
				xendpointarray=Array.concat(xendpointarray,x);
				yendpointarray=Array.concat(yendpointarray,y);
			}
			positionArrayLength=lengthOf(xpositionarray);
			touchingpixels=Array.concat(touchingpixels,positionArrayLength);
		}
		if (x==x0+boxwidth){
			x=x0;
			y=y+1;
		}
		else{
			x=x+1;
		}	
	}
}
function getLineEq(n0){							//n0 is the number of pixels used to generate slopes. If you want to use the whole line, enter "infinity";		
	l=0;
	while (l<xendpointarray.length){		//for every endpoint, expand until an intersection or other endpoint
		x=xendpointarray[l];
		y=yendpointarray[l];
		if (true){
			index1=0;
			q=true;							
			xpositionarray=newArray();
			ypositionarray=newArray();
			xpositionarray1=newArray();
			ypositionarray1=newArray();
			xpositionarray=Array.concat(xpositionarray, x);
			ypositionarray=Array.concat(ypositionarray, y);
			x2=0;
			y2=0;
			x3=0;
			y3=0;
			while (q==true){
				touchingpoints=newArray();
				condition5=true;
				if (index1==4){  //if the non-(x,y) points surrounding the center touch, then it's not an intersection. If they do not touch, it exits the line expansion.
					
					condition5=false;
					for (i=0; i<lengthOf(pointarray); i++){
						condition1=false;
						condition2=false;
						if (startsWith(pointarray[i], ""+toString(x)+",") || startsWith(pointarray[i], ""+toString(x-1)+",") || startsWith(pointarray[i], ""+toString(x+1)+",")){
							condition1=true;
						}
						if (endsWith(pointarray[i], ","+toString(y)) || endsWith(pointarray[i], ","+toString(y-1)) || endsWith(pointarray[i], ","+toString(y+1))){
							condition2=true;
						}
						if (condition1==true && condition2==true){
							touchingpoints=Array.concat(touchingpoints, i);  //makes an array with reference points to the pixels touching x,y
						}
					}
					touchingpoints3=newArray();
					for (z=0; z<lengthOf(touchingpoints); z++){
						status1=true;
						
						x4=xpointarray[touchingpoints[z]];
						y4=ypointarray[touchingpoints[z]];
						if (x4==x && y4==y){ 		//if it is the same point as xy, don't check the position (we only care about the non xy points in the array)
							status1=false;
							
						}
						if (x4==x2 && y4==y2){
							status1=false;
							
						}
						if (x4==x3 && y4==y3){
							status1=false;
							
						}
						if (getPixel(x4,y4)==0){
							status1=false;
						}
						if (status1==true){
							touchingpoints3=Array.concat(touchingpoints3, touchingpoints[z]); //makes an array out of the points touching x,y that could possibly be the next pixel in the line
						}
						
					}
					for (c=0; c<lengthOf(touchingpoints3); c++){				//if those pixels are on cardinal directions from x,y but not touching eachother, it's probably an intersection.
						for (d=0; d<lengthOf(touchingpoints3); d++){
							status2=true;
							if (xpointarray[touchingpoints3[d]]==xpointarray[touchingpoints3[c]] && ypointarray[touchingpoints3[d]]==ypointarray[touchingpoints3[c]]){
								status2=false;
							}
							if(status2==true){	
								if (xpointarray[touchingpoints3[d]]>=xpointarray[touchingpoints3[c]]-1 && xpointarray[touchingpoints3[d]]<=xpointarray[touchingpoints3[c]]+1){
									
									if (ypointarray[touchingpoints3[d]]>=ypointarray[touchingpoints3[c]]-1 && ypointarray[touchingpoints3[d]]<=ypointarray[touchingpoints3[c]]+1){
										
										if (xpointarray[touchingpoints3[d]]==xpointarray[touchingpoints3[c]] || ypointarray[touchingpoints3[d]]==ypointarray[touchingpoints3[c]]){
											condition5=true;
										}
									}
								}
							}
						}
					}
				}
				touchingpoints=newArray();	
				if (index1>4||index1==2||condition5==false){		//if the point is an intersection or an endpoint, pixels are no longer added to the position array. Condition 5 tells us whether a pixel with 3 neighboring pixels is an intersection or not. 
					q=false;
					if (index1==2){
						doneEnds=Array.concat(doneEnds, toString(x)+","+toString(y));
					}
				}
				else{
					xpositionarray1=newArray();
					ypositionarray1=newArray();				
					for (i=0; i<lengthOf(pointarray); i++){
						condition1=false;
						condition2=false;
						if (parseInt(startsWith(pointarray[i], ""+toString(x)+",")) || parseInt(startsWith(pointarray[i], ""+toString(x-1)+",")) || parseInt(startsWith(pointarray[i], ""+toString(x+1)+","))){
							condition1=true;
						}
						if (parseInt(endsWith(pointarray[i], ","+toString(y))) || parseInt(endsWith(pointarray[i], ","+toString(y-1))) || parseInt(endsWith(pointarray[i], ","+toString(y+1)))){
							condition2=true;
						}
						if (condition1==true && condition2==true){
							touchingpoints=Array.concat(touchingpoints, i);
						}
					}
					for (i=0; i<lengthOf(touchingpoints); i++){
						x00=xpointarray[touchingpoints[i]];
						y00=ypointarray[touchingpoints[i]];
						status1=true;
						if (x00==x && y00==y){ 
							status1=false;
						}	
						if (x00==x2 && y00==y2){
							status1=false;
						}
						if (x00==x3 && y00==y3){
							status1=false;
						}
						if (status1==true){
							xpositionarray1=Array.concat(xpositionarray1,x00);
							ypositionarray1=Array.concat(ypositionarray1,y00);
						}
					}
					if (lengthOf(xpositionarray1)>1){								//expands line to the pixel at cardinal directions if there are 3 touching and it's not an intersection
						for (i=0; i<lengthOf(xpositionarray1); i++){
							if (xpositionarray1[i]==x || ypositionarray1[i]==y){
								x3=x2;
								y3=y2;
								x2=x;
								y2=y;
								x=xpositionarray1[i];
								y=ypositionarray1[i];
								xpositionarray=Array.concat(xpositionarray, x);
								ypositionarray=Array.concat(ypositionarray, y);
								t=index(pointarray,toString(x)+","+toString(y));
								index1=touchingpixels[t];
							}
						}
					}
					else if (lengthOf(xpositionarray1)==0){
						q=false;
					}
					else {
						x3=x2;
						y3=y2;
						x2=x;
						y2=y;
						x=xpositionarray1[0];
						y=ypositionarray1[0];
						xpositionarray=Array.concat(xpositionarray, x);
						ypositionarray=Array.concat(ypositionarray, y);
						t=index(pointarray,toString(x)+","+toString(y));
						index1=touchingpixels[t];
					}
				}
			}
			if (index(doneEnds, toString(xendpointarray[l])+","+toString(yendpointarray[l]))==-1){
				linelengths=Array.concat(linelengths, lengthOf(xpositionarray));
			}
			//all the line stuff
			sumx=0;						//least squares regression
			sumy=0;
			sumxy=0;
			sumxsquared=0;
			n=n0;
			if (toString(n0)=="infinity" || n0>lengthOf(xpositionarray)){
				n=lengthOf(xpositionarray);	
			}
			for (i=0; i<n; i++){
				sumx=sumx+xpositionarray[i];
				sumy=sumy+ypositionarray[i];
				sumxy=sumxy+(xpositionarray[i]*ypositionarray[i]);
				sumxsquared=sumxsquared+pow(xpositionarray[i],2);
			}
			m1=parseFloat(((n*sumxy)-(sumx*sumy))/((n*sumxsquared)-(pow(sumx,2))));
			b1=parseFloat((sumy-(m1*sumx))/n);
			angle=abs(atan(m1));
			Array.getStatistics(xpositionarray, min, max, mean, stdDev);
			xmean=mean;
			Array.getStatistics(ypositionarray, min, max, mean, stdDev);
			ymean=mean;
			if (((n*sumxsquared)-(pow(sumx,2)))==0){
				m1=999;
				b1=y;
				if(ymean>yendpointarray[l]){
					angle=(PI/2);
				}
				else{
					angle=3*(PI/2);
				}
			}
			else if (m1==0){
				if(xmean>xendpointarray[l]){		//no entries into array on top because slope is 0. If second entry is right of the endpoint, then open space is on 
					//the left and angle is pi, not 0. Array.getStatistics(maxarray, min, max, mean, stdDev);
					angle=PI;
				}
				else{
					angle=0;
				}
			}	
			else if (xmean>xendpointarray[l] && ymean<yendpointarray[l]){
				angle=(PI)+angle;
			}
			else if (xmean<xendpointarray[l] && ymean<yendpointarray[l]){
				angle=(2*PI)-angle;
			}
			else if (xmean<xendpointarray[l] && ymean>yendpointarray[l]){	
				angle=0+angle;
			}
			else if(xmean>xendpointarray[l] && ymean>yendpointarray[l]){
				angle=(PI)-angle;
			}	
	
			marray=Array.concat(marray,m1);
			barray=Array.concat(barray,b1);
			anglearray=Array.concat(anglearray,angle);
		}
		l=l+1;
	}		
}
			
function bound (angle,finangle){
	status=false;
	if (angle<=upperbound && angle>=lowerbound){
		if (finangle<=upperbound && finangle>=lowerbound){
			status=true;
		}
	}
	return status;
}

function bound2 (angle,finangle){
	status=false;
	if (angle<=upperbound||angle>=lowerbound){
		if (finangle<=upperbound||finangle>=lowerbound){
			status=true;
		}
	}
	return status;
}
	
function connectends(len,deg){				//finds endpoints, connecting them if length between them is less than the variable len pixels and if the angle of
											//the angle of the line is within deg degrees (not radians!) of the angle of the local slope.
	refangle=deg/180*PI;					//degrees to radians
	i=0;
	while (i<xendpointarray.length){		//scans through pairs of endpoints
		o=0;
		while (o<xendpointarray.length){
			xorigin=xendpointarray[i];
			yorigin=yendpointarray[i];
			xfin=xendpointarray[o];
			yfin=yendpointarray[o];
			xd=xfin-xorigin;
			yd=yorigin-yfin;
			length=sqrt((pow((xd),2))+(pow((yd),2)));
			if (length<len){				//length check of line
				angle=atan2(yd,xd);			//uses atan2 to get the angle of the line between endpoints
				if (angle<0){				//changes negative angles to positive
					angle=(2*PI)-abs(angle);
				}
				upperbound=anglearray[i]+refangle;		//sets upper and lower bounds of the range of angles acceptable for joining endpoints
				lowerbound=anglearray[i]-refangle;		//the next two if statements set the bounds if angles may cross the 0 threshold
				finangle=anglearray[o]+PI;
				if (finangle>2*PI){
					finangle=finangle-(2*PI);
				}
				if (anglearray[i]-refangle<0){		
					upperbound=anglearray[i]+refangle;
					lowerbound=(2*PI)+(anglearray[i]-refangle);
					if (bound2(angle, finangle)==true){
						if (angle>0 && angle<PI/2){
							makeLine(xorigin+1,yorigin-1,xfin-1,yfin+1);
							getRawStatistics(nPixels, mean, min, max, std);
							if (mean<1){
								setForegroundColor(0, 0, 0);
								run("Draw");
							} 
						}
						if (angle>PI/2 && angle<PI){
							makeLine(xorigin-1, yorigin-1, xfin+1, yfin+1);
							getRawStatistics(nPixels, mean, min, max, std);
							if (mean<1){
								setForegroundColor(0, 0, 0);
								run("Draw");
							}
						}
						if (angle>PI && angle<3*PI/2){
							makeLine(xorigin-1, yorigin+1, xfin+1, yfin-1);
							getRawStatistics(nPixels, mean, min, max, std);
							if (mean<1){
								setForegroundColor(0, 0, 0);
								run("Draw");
							}
						}
						if (angle>3*PI/2 && angle<2*PI){
							makeLine(xorigin+1,yorigin+1,xfin-1,yfin-1);
							getRawStatistics(nPixels, mean, min, max, std);
							if (mean<1){
								setForegroundColor(0, 0, 0);
								run("Draw");
							}	
						}
						if (angle==0){
							makeLine(xorigin+1, yorigin, xfin-1, yfin);
							getRawStatistics(nPixels, mean, min, max, std);
							if (mean<1){
								setForegroundColor(0, 0, 0);
								run("Draw");
							}
						}
						if (angle==PI/2){
							makeLine(xorigin, yorigin-1, xfin, yfin+1);
							getRawStatistics(nPixels, mean, min, max, std);
							if (mean<1){
								setForegroundColor(0, 0, 0);
								run("Draw");
							}
						}
						if (angle==PI){
							makeLine(xorigin-1, yorigin, xfin+1, yfin);
							getRawStatistics(nPixels, mean, min, max, std);
							if (mean<1){
								setForegroundColor(0, 0, 0);
								run("Draw");
							}
						}
						if (angle==3*PI/2){
							makeLine(xorigin, yorigin+1, xfin, yfin-1);
							getRawStatistics(nPixels, mean, min, max, std);
							if (mean<1){
								setForegroundColor(0, 0, 0);
								run("Draw");
							}
						}		
					}
				}
				else if (anglearray[i]+refangle>2*PI){
					upperbound=0+(anglearray[i]+refangle)-2*PI;
					lowerbound=anglearray[i]-refangle;
					if (bound2(angle, finangle)==true){
						if (angle>0 && angle<PI/2){
							makeLine(xorigin+1,yorigin-1,xfin-1,yfin+1);
							getRawStatistics(nPixels, mean, min, max, std);
							if (mean<1){
								setForegroundColor(0, 0, 0);
								run("Draw");
							}
						}
						if (angle>PI/2 && angle<PI){
							makeLine(xorigin-1, yorigin-1, xfin+1, yfin+1);
							getRawStatistics(nPixels, mean, min, max, std);
							if (mean<1){
								setForegroundColor(0, 0, 0);
								run("Draw");
							}
						}
						if (angle>PI && angle<3*PI/2){
							makeLine(xorigin-1, yorigin+1, xfin+1, yfin-1);
							getRawStatistics(nPixels, mean, min, max, std);
							if (mean<1){
								setForegroundColor(0, 0, 0);
								run("Draw");
							}
						}
						if (angle>3*PI/2 && angle<2*PI){
							makeLine(xorigin+1,yorigin+1,xfin-1,yfin-1);
							getRawStatistics(nPixels, mean, min, max, std);
							if (mean<1){
								setForegroundColor(0, 0, 0);
								run("Draw");
							}	
						}
						if (angle==0){
							makeLine(xorigin+1, yorigin, xfin-1, yfin);
							getRawStatistics(nPixels, mean, min, max, std);
							if (mean<1){
								setForegroundColor(0, 0, 0);
								run("Draw");
							}
						}
						if (angle==PI/2){
							makeLine(xorigin, yorigin-1, xfin, yfin+1);
							getRawStatistics(nPixels, mean, min, max, std);
							if (mean<1){
								setForegroundColor(0, 0, 0);
								run("Draw");
							}
						}
						if (angle==PI){
							makeLine(xorigin-1, yorigin, xfin+1, yfin);
							getRawStatistics(nPixels, mean, min, max, std);
							if (mean<1){
								setForegroundColor(0, 0, 0);
								run("Draw");
							}
						}
						if (angle==3*PI/2){
							makeLine(xorigin, yorigin+1, xfin, yfin-1);
							getRawStatistics(nPixels, mean, min, max, std);
							if (mean<1){
								setForegroundColor(0, 0, 0);
								run("Draw");
							}
						}
					}
				}
				else{
					if (bound(angle, finangle)==true){
						if (angle>0 && angle<PI/2){
							makeLine(xorigin+1,yorigin-1,xfin-1,yfin+1);
							getRawStatistics(nPixels, mean, min, max, std);
							if (mean<1){
								setForegroundColor(0, 0, 0);
								run("Draw");
							}
						}
						if (angle>PI/2 && angle<PI){
							makeLine(xorigin-1, yorigin-1, xfin+1, yfin+1);
							getRawStatistics(nPixels, mean, min, max, std);
							if (mean<1){
								setForegroundColor(0, 0, 0);
								run("Draw");
							}
						}
						if (angle>PI && angle<3*PI/2){
							makeLine(xorigin-1, yorigin+1, xfin+1, yfin-1);
							getRawStatistics(nPixels, mean, min, max, std);
							if (mean<1){
								setForegroundColor(0, 0, 0);
								run("Draw");
							}
						}
						if (angle>3*PI/2 && angle<2*PI){
							makeLine(xorigin+1,yorigin+1,xfin-1,yfin-1);
							getRawStatistics(nPixels, mean, min, max, std);
							if (mean<1){
								setForegroundColor(0, 0, 0);
								run("Draw");
							}	
						}
						if (angle==0){
							makeLine(xorigin+1, yorigin, xfin-1, yfin);
							getRawStatistics(nPixels, mean, min, max, std);
							if (mean<1){
								setForegroundColor(0, 0, 0);
								run("Draw");
							}
						}
						if (angle==PI/2){
							makeLine(xorigin, yorigin-1, xfin, yfin+1);
							getRawStatistics(nPixels, mean, min, max, std);
							if (mean<1){
								setForegroundColor(0, 0, 0);
								run("Draw");
							}
						}
						if (angle==PI){
							makeLine(xorigin-1, yorigin, xfin+1, yfin);
							getRawStatistics(nPixels, mean, min, max, std);
							if (mean<1){
								setForegroundColor(0, 0, 0);
								run("Draw");
							}
						}
						if (angle==3*PI/2){
							makeLine(xorigin, yorigin+1, xfin, yfin-1);
							getRawStatistics(nPixels, mean, min, max, std);
							if (mean<1){
								setForegroundColor(0, 0, 0);
								run("Draw");
							}
						}
					}						 
				}
			}
			o=o+1;
		}
		i=i+1;
	}	
}

//////////////////////////////////////////////////////////////////////////////////



function connectEnds(x0,y0,boxwidth,decision,decision2,endlim,anglim){
	//this macro connects skeletonized endpoints if they are close and the line between them has a similar trajectory to the local slope of the endpoint. It does not count branches that are only one pixel away fronm the branch point 
	//must seletonize your vessels before begininng.
	xpointarray=newArray(); 			//x coordinates for each black skeletonized pixel
	ypointarray=newArray();				//y coordinates for each black skeletonized pixel
	xendpointarray=newArray(); 			//x coordinates for each black skeletonized pixel meeting criteria as an endpoint
	yendpointarray=newArray();			//y coordinates for each black skeletonized pixel meeting criteria as an endpoint
	marray=newArray();					//slope of black skeletonized pixel meeting criteria as an endpoint
	barray=newArray();					//y-intercept of perpendicular line at each black skeletonized pixel
	touchingpixels=newArray();			//<3 means intersection (usually), 2 means endpoint
	anglearray=newArray();				//array containing the angle of the local linear best fit line, in radians
	pointarray=newArray();
	linelengths=newArray();
	doneEnds=newArray();
	upperbound=0;
	lowerbound=0;		
	
	findEnds(x0,y0,boxwidth);
	if (decision2==1){
		getLineEq(states[9]);
		connectends(endlim,anglim);
	}	
	junctioncount=0;
	if (decision==1){
		for (h=0; h<lengthOf(xpointarray); h++){
			if (touchingpixels[h]>3){
				setPixel(xpointarray[h],ypointarray[h],0);
					junctioncount=junctioncount+1;
			}
		}
	}
}

function runInSquares(wid,decision,decision2,decision3,endlim,anglim) {			//width of square
	x=0;
	y=0;
	while (y<getHeight){
		connectEnds(x,y,wid,decision,decision2,endlim,anglim);
		if (decision3==1){
			junctioncount2=junctioncount2+junctioncount;
		}
		if (x>getWidth){ 
			x=0;
			y=y+(wid-10);
			}
			else{
				x=x+(wid-10);
			}
	}
}
function check(){
	getHistogram(values, counts, 2);
	Array.getStatistics(counts, min, max, mean, stdDev);
	rat=counts[1]/counts[0];
	return rat
}

//////////////////////////////////////////////////////////////////////////////////
//determines whether the tiff contains two channels, splitting them if true. Makes stack for FWHM. Trims stack to middle n1 number of slices
function prepare(n1){
	roiManager("Select", 0);
	run("Duplicate...", "duplicate");
	rename("test");
	run("Subtract Background...", "rolling=5 stack");
	setSlice(3/4*nSlices);
	con1=check();
	setSlice(1/4*nSlices);
	con2=check();
	setSlice(1/2*nSlices);
	con3=check();
	close("test");
	stat=1;
	if (nSlices%2==1){
		stat=0;
	}
	else{
		if (nSlices<=18){
			stat=0;
		}
		else{
			if (con1<0.005 && con2>0.005){
				stat=1;
			}
			if (con1>0.005 && con2<0.005){
				stat=1;
			}
			if (con3<0.01){
				stat=1;
			}
		}
	}
	if(states[4]==2){
		stat=1;
	}
	if(states[4]==3){
		stat=0;
	}
	if (stat==0){
		slice=nSlices;
	}
	else{
		slice=nSlices/2;
	}
	if (stat==1){
		print("split");
		run("Stack Splitter", "number=2");
		if (n1>nSlices){
			n=nSlices;
		}
		else{
			n=n1;
		}
		selectWindow("stk_0002_"+name);
		start=round(((nSlices)-n)/2)+1;
		stop=start+(n-1);
		run("Make Substack...", "  slices="+start+"-"+stop);
		rename("MAX_A-0002");
		selectWindow("stk_0001_"+name);
		run("Make Substack...", "  slices="+start+"-"+stop);
		rename("MAX_A-0001");
		if (con1>con2){
			print("switch");
			selectWindow("MAX_A-0001");
			rename("MAX_A-0002-1");
			selectWindow("MAX_A-0002");
			rename("MAX_A-0001");
			selectWindow("MAX_A-0002-1");
			rename("MAX_A-0002");
			selectWindow("stk_0002_"+name);
			rename("stk_0011_"+name);
			selectWindow("stk_0001_"+name);
			rename("stk_0002_"+name);
			selectWindow("stk_0011_"+name);
			rename("stk_0001_"+name);
		}
		selectWindow("stk_0002_"+name);
		nROIs=roiManager("count");
		beads=countMaxima(n1);
		allBeads=beads[1];	//counts all maxima
		restrictedBeads=beads[0];	//counts maxima in the ROI
		close("stk_0002_"+name);
		selectWindow("stk_0001_"+name);
		saveAs("Tiff", par1+"\\Vessel Macro Output\\FWHM_stack");	//saves a stack to do FWHM on
		rename("stack");
		close("stack");
		selectWindow("MAX_A-0001");
		rename("Result of MAX_A-0001");
		numslices=nSlices;
	}
	else {
		print("no split");
		if (n1>nSlices){
			n=nSlices;
		}
		else{
			n=n1;
		}
		saveAs("Tiff", par1+"\\Vessel Macro Output\\FWHM_stack");	//saves a stack to do FWHM on
		rename("stack");
		start=round(((nSlices)-n)/2)+1;
		stop=start+(n-1);
		run("Select None");
		run("Make Substack...", "  slices="+start+"-"+stop);
		rename("Result of MAX_A-0001");
		close("stack");
		nROIs=roiManager("count");
		numslices=nSlices;
	}
}	

function process(){
	selectWindow("Result of MAX_A-0001");
	if (nSlices==1){
		roiManager("Select", 0);
		rat=check();
	}
	else{
		setSlice(nSlices/2);
		roiManager("Select", 0);
		rat=check();
	}
	if (isOpen("MAX_A-0002")==1){
		selectWindow("Result of MAX_A-0001");
		rename("MAX_A-0001");
		selectWindow("MAX_A-0001");
		setSlice(nSlices/2+1);
		roiManager("Select", 0);
		getHistogram(values, counts, 64,0,2000);
		Array.getStatistics(counts, min, max, mean, stdDev);
		h=index(counts,max);
		mean1=values[h];
		selectWindow("MAX_A-0002");
		setSlice(nSlices/2+1);
		roiManager("Select", 0);
		getHistogram(values, counts, 64,0,2000);
		Array.getStatistics(counts, min, max, mean, stdDev);
		h=index(counts,max);
		mean2=values[h];
		factor=mean1/mean2;
		selectWindow("MAX_A-0002");
		for (g=1; g<nSlices+1; g++){
			setSlice(g);
			backgroundmultiply(factor*states[7]);
		}
		run("Maximum...", "radius=1 stack");
		selectWindow("MAX_A-0001");
		run("Select None");
		run("Duplicate...", "duplicate");
		rename("duplicate");
		run("Subtract Background...", "rolling=5 stack");
		run("Duplicate...", "duplicate");
		rename("2");
		run("Z Project...", "projection=[Max Intensity]");
		setAutoThreshold("Li dark no-reset");
		setOption("BlackBackground", false);
		run("Convert to Mask");
		run("Analyze Particles...", "size=0-20 pixel show=Masks");
		run("16-bit");
		backgroundmultiply(16);
		rename("noise");
		close("MAX_2");
		close("2");
		imageCalculator("Subtract create stack", "duplicate","noise");
		close("noise");
		close("duplicate");
		rename("duplicate");
		imageCalculator("Subtract create stack", "MAX_A-0002","duplicate");
		imageCalculator("Subtract create stack", "MAX_A-0001","Result of MAX_A-0002");
		close("MAX_A-0002");
		close("MAX_A-0001");
		close("Result of MAX_A-0002");
		close("duplicate");
		rename("duplicate");
		run("Z Project...", "projection=[Max Intensity]");
		setAutoThreshold("Li dark no-reset");
		setOption("BlackBackground", false);
		run("Convert to Mask");
		run("Analyze Particles...", "size=0-20 pixel show=Masks");
		run("16-bit");
		backgroundmultiply(16);
		rename("noise");
		close("MAX_duplicate");
		imageCalculator("Subtract create stack", "duplicate","noise");
		rename("Result of MAX_A-0001");
		close("duplicate");
		close("noise");
	}
	else{
		rename("Result of MAX_A-0001");
	}
}

//////////////////////////////////////////////////////////////////////////////////
//Whole macro that incorporates above functions that can be repeated

function doit(stack){
	dir=File.directory;
	name=getTitle;
	rawName=replace(name,".tif","");
	par1=File.getParent(dir);
	nROIs = roiManager("count");
	print(name);
	if (nROIs!=0){
		roiManager("Select", 0);
		roiManager("Deselect");
		roiManager("Delete");
	}
	if (File.exists(par1+"\\ROIs\\"+rawName+"_RoiSet.zip")==1){
		open(par1+"\\ROIs\\"+rawName+"_RoiSet.zip");
		nROIs = roiManager("count");
		if (nROIs>1){
			roiManager("Select", 1);
		}
		else{
			roiManager("Select", 0);
			run("Make Inverse");
			roiManager("Add");
			roiManager("Select", 1);
		}
		roiManager("Select", 0);
		roiManager("Remove Slice Info");
		roiManager("Select", 1);
		roiManager("Remove Slice Info");
	}
	else{
		print("No ROI info. Used whole image.");	
		run("Select All");
		roiManager("Add");
		roiManager("Select", 0);
		roiManager("Remove Slice Info");
	}
	run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
	if (File.exists(par1+"\\Vessel Macro Output")==0){
		File.makeDirectory(par1+"\\Vessel Macro Output");
	}
	if (File.exists(par1+"\\Vessel Macro Output\\skeletons")==0){
		File.makeDirectory(par1+"\\Vessel Macro Output\\skeletons");
		File.makeDirectory(par1+"\\Vessel Macro Output\\masks");
	}
	prepare(states[3]);
	nROIs = roiManager("count");
	if (isOpen("MAX_A-0002")==1){
		selectWindow("MAX_A-0002");
		if (nROIs>1){
			roiManager("Select", 1);
			setBackgroundColor(255, 255, 255);
			run("Clear", "stack");
		}	
	}
	roiManager("Select", 0);
	selectWindow("Result of MAX_A-0001");
	process();
	run("Subtract Background...", "rolling=5 stack");
	if (nROIs>1){
		roiManager("Select", 1);
		setBackgroundColor(0, 0, 0);
		run("Clear", "stack");
	}
	run("Select None");
	run("Duplicate...", "duplicate");
	rename("substack");
	selectWindow("Result of MAX_A-0001");
	run("Z Project...", "projection=[Max Intensity]");
	close("Result of Max_A-0001");
	rename("Result of MAX_A-0001");
	selectWindow("substack");
	run("Z Project...", "projection=[Max Intensity]");
	close("substack");
	rename("substack");
	if (File.exists(par1+"\\Vessel Macro Output")==0){
		File.makeDirectory(par1+"\\Vessel Macro Output");
	}
	if (true==true){
		close("MAX_A-0002");
		selectWindow("Result of MAX_A-0001");
		saveAs("Tiff", par1+"\\Vessel Macro Output\\full");
		close("full.tif");
		selectWindow("substack");
		close("substack");
		wait(2000);
		call("trainableSegmentation.Weka_Segmentation.applyClassifier", par1+"\\Vessel Macro Output\\", "full.tif", "showResults=true", "storeResults=false", "probabilityMaps=false", "");
		titles=getList("image.titles");
		if (index(titles,"Classification result")==-1){
			close("Trainable Weka Segmentation v3.2.28");
			run("Trainable Weka Segmentation");
			wait(1000);
			call("trainableSegmentation.Weka_Segmentation.loadClassifier", classifier);
			wait(1000);
			call("trainableSegmentation.Weka_Segmentation.applyClassifier", par1+"\\Vessel Macro Output\\", "full.tif", "showResults=true", "storeResults=false", "probabilityMaps=false", "");
		}
		close (name);
		close("full.tif");
		selectWindow("Classification result");
		setThreshold(0, 0);
		setOption("BlackBackground", false);
		run("Convert to Mask");
		rename("Result of MAX_A-0001");
		saveAs("Tiff", par1+"\\Vessel Macro Output\\Result of MAX_A-0001");
		close("Result of MAX_A-0001.tif");
		open(par1+"\\Vessel Macro Output\\Result of MAX_A-0001.tif");
		rename("Result of MAX_A-0001");
		selectWindow("Result of MAX_A-0001");
		run("8-bit");
		run("Median...", "radius=1");
		if (nROIs>1){
			roiManager("Select", 1);
			setBackgroundColor(255, 255, 255);
			run("Clear", "stack");
		}
		run("Select None");
		run("Analyze Particles...", "size=20-Infinity pixel show=Masks");
		close("Result of MAX_A-0001");
		selectWindow("Mask of Result of MAX_A-0001");
		rename("Result of MAX_A-0001");
	}
	pixelWidth=states[0];
	roiManager("Select", 0);
	getRawStatistics(nPixels, mean, min, max, std);
	proiarea=nPixels;
	roiManager("Deselect");
	run("Create Selection");
	run("Make Inverse");
	nROIs=roiManager("count");
	roiManager("Add");
	roiManager("Select", nROIs);
	roiManager("Save", par1+"\\Vessel Macro Output\\FWHMROI.roi");
	run("Make Inverse");
	getRawStatistics(nPixels, mean, min, max, std);
	pvesselarea=nPixels;
	varea=pow(sqrt(pvesselarea)*pixelWidth,2);
	varea1=varea/1000000;
	roiarea=pow(sqrt(proiarea)*pixelWidth,2);
	roiarea1=roiarea/1000000;
	
	saveAs("Tiff", par1+"\\Vessel Macro Output\\masks\\"+rawName);
	
	run("Skeletonize (2D/3D)");
	runInSquares(states[6],0,1,0,states[8],states[10]);
	blackpixel=(blackpixelcount());
	length=blackpixel;
	length1=length*pixelWidth;
	print(length,length1);
	roiManager("Select", 0);
	width=varea/length1;
	vvol=(3.141592*length1*pow((width/2),2))/1000000000;
	run("Set Scale...", "distance=1 known="+pixelWidth+" unit=um");
	saveAs("Tiff", par1+"\\Vessel Macro Output\\skeletons\\"+rawName);
	close(name);
	close(rawName+"_mask.tif");
	close("Max_Result of MAX_A-0001");
	close("Result of MAX_A-0001");
	close(rawName+"_skeleton1.tif");
	
	roiManager("Deselect");
	roiManager("Delete");
	open(dir+name);
	run("Open Next");
}



dir=File.directory;
name=getTitle;
rawName=replace(name,".tif","");
par1=File.getParent(dir);
directarray=getFileList(dir);
states=params();

class100=par1+"\\classifier 100.model";
classfin=par1+"\\classifier final2.model";

if(states[2]==100){
	classifier=class100;
	classifier1=class100;
}
else{
	classifier=classfin;
	classifier1=classfin;
}

run("Trainable Weka Segmentation");
wait(2000);
call("trainableSegmentation.Weka_Segmentation.loadClassifier", classifier);
wait(1000);
selectWindow(name);
close(name);
open(dir+name);
if	(states[5]==1){
	for (i=0; i<lengthOf(directarray); i++){
		doit(1);
	}	
}
else{
	doit(1);
}	


