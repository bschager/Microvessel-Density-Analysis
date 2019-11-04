//This macro takes opens a skeleton (defined by a name ending in "_skeleton1.tif") and divides it into 170x170 pixels subsections
//it deletes parts of the box that are not in the ROI, and reports the length density of the skeleton in subsections greater than 1/3 the maximum subsection ROI area
//macro is designed to be run on the output folder of Schager_v6 Vessel Density Plugin.ijm

var areas1=newArray("CCW","Fim","FrA","GIC","PRh","mot","S1F","RSG","V1C","HPC","STR","tha","Hyp","BLA","SNR");
var yden=newArray(0.5508,0.3908,1.042,0.7931,0.7435,1.069,1.159,1.186,0.9474,0.7569,0.9134,1.164,0.7299,0.7043,0.7852);
var aden=newArray(0.3669,0.3367,0.9557,0.7585,0.6229,0.9565,1.075,1.087,0.9187,0.6823,0.8661,1.111,0.6413,0.6943,0.7207);

function divideROIs() {		
	x=2;
	y=2;
	while (y+3<getHeight){
		run("Select None");
		nROIs=roiManager("count");
		makeRectangle(x,y,170,170);
		roiManager("Add");
		roiManager("Select", newArray(0,nROIs));
		roiManager("AND");
		type=selectionType(); 
		if (selectionType()!=-1){
			roiManager("Add");
		}
		roiManager("Deselect");
		roiManager("Select", nROIs);
		roiManager("Delete");
		if (x+173>getWidth){ 
			x=2;
			y=y+170;
			}
			else{
				x=x+170;
			}
	}
}

function index(a,value){
	for(i=0; i<a.length; i++)
		if (a[i]==value) return i;		
	return -1;
}

dir=getDirectory("Choose a Directory");
directarray=getFileList(dir);
par1=File.getParent(dir);
par2=File.getParent(par1);
//close(name);

stds=newArray();
names=newArray();
res=0;

if (File.exists(par1+"\\Marked Skeletons")!=1){
	File.makeDirectory(par1+"\\Marked Skeletons");
}
for(z=0; z<lengthOf(directarray); z++)
{
open(dir+directarray[z]);
name=getTitle;
run("Set Scale...", "distance=0.8052 known=1 pixel=1 unit=µm");
run("Select None");
run("Duplicate...", " ");
rename("2");
run("RGB Color");
selectWindow(name);
for (i = 0; i < lengthOf(areas1); i++) {
	area1=indexOf(name, areas1[i]);
	if (area1!=-1){
		realarea=areas1[i];
	}
}

rawName=replace(name,".tif","");
par1=File.getParent(dir);
run("Remove Overlay");
nROIs = roiManager("count");
if (nROIs!=0){
	roiManager("Select", 0);
	roiManager("Deselect");
	roiManager("Delete");
}
open(par2+"\\ROIs\\"+rawName+"_RoiSet.zip");
nROIstart = roiManager("count");

divideROIs();

run("Clear Results");
run("Set Measurements...", "area area_fraction redirect=None decimal=9");
run("Select None");

areas=newArray();
perAreas=newArray();
densities=newArray();

roiManager("Select", 0);
run("Measure");
totalArea=getResult("Area",0);
run("Analyze Skeleton (2D/3D)", "prune=none show");
selectWindow("Tagged skeleton");
close();
IJ.renameResults("Branch information","Results")
brlen=0;
eulen=0;

for (j = 0; j < nResults; j++) {
	brlen=brlen+getResult("Branch length", j);
	eulen=eulen+getResult("Euclidean distance", j);
}
totalPerArea=brlen;

for (i=0 ; i<nROIstart; i++) {
	roiManager("Select", 0);
	roiManager("Delete");
}
lown=0;
n=0;
nROIs=roiManager("count");
for (i=0; i<nROIs; i++) {	
	roiManager("Select", i);
	getStatistics(area);
	if (area>1/3*44580.2){
		n=n+1;
		run("Duplicate...", " ");
		rename("1");
		if (selectionType()==-1){
			run("Select All");
		}
		roiManager("Add");
		run("Clear Results");
		run("Measure");
		Area=getResult("Area",0);
		run("Clear Results");
		run("Analyze Skeleton (2D/3D)", "prune=none show");
		selectWindow("Tagged skeleton");
		close();
		IJ.renameResults("Branch information","Results")
		brlen=0;
		eulen=0;
		for (j = 0; j < nResults; j++) {
			brlen=brlen+getResult("Branch length", j);
			//eulen=eulen+getResult("Euclidean distance", j);
		}
		brlen=(brlen/1000000);
		Area=(Area*38/1000000000);
		run("Clear Results");
		density=brlen/Area;
		density=(density*1.191)-0.04949;
		//densities=Array.concat(densities,density);
		perAreas=Array.concat(perAreas,brlen);
		areas=Array.concat(areas,Area);
		roiManager("Select", nROIs);
		roiManager("Delete");
		close("1");
		selectWindow("2");
		selectWindow("2");
		roiManager("Select", i);
		run("Set Scale...", "distance=1 known=1 pixel=1 unit=µm");
		run("Set Measurements...", "centroid redirect=None decimal=9");
		run("Measure");
		x=getResult("X", 0);
		y=getResult("Y", 0);
		run("Set Scale...", "distance=0.8052 known=1 pixel=1 unit=µm");
		run("Clear Results");
		run("Set Measurements...", "area area_fraction redirect=None decimal=9");
		if (density < 0.5*yden[index(areas1,realarea)]){
			roiManager("Select", i);
			run("Colors...", "foreground=red background=white selection=yellow");
			run("Draw", "slice");
			lown=lown+1;
		}
		else{
			roiManager("Select", i);
			run("Colors...", "foreground=black background=white selection=yellow");
			run("Draw", "slice");
		}
		run("Colors...", "foreground=magenta background=white selection=yellow");
		//drawString(density, x, y);
		drawString(density,x,y);
		drawString(brlen,x,y+10);
		drawString(Area,x,y+20);
		run("Colors...", "foreground=black background=white selection=yellow");
		selectWindow(name);
		selectWindow(name);
	}
}

selectWindow("Results");
run("Clear Results");
run("Set Measurements...", "  redirect=None decimal=9"); 
if (isOpen("GOB")==1){
	run("Close");
	IJ.renameResults("GOB","Results");
}
setResult("File", res,rawName);
setResult("Total Area", res, totalArea);
setResult("Total length", res, totalPerArea);
for (i=0; i<lengthOf(areas);i++){
	setResult("Area "+i, res,areas[i]);
	setResult("Length "+i, res,perAreas[i]);
}
IJ.renameResults("Results","GOB");

if (isOpen("Summary Ben")==1){
	IJ.renameResults("Summary Ben","Results");
}
setResult("File", res,rawName);
setResult("Number of sampled", res, n);
setResult("Number under 50%", res, lown);
IJ.renameResults("Results","Summary Ben");
selectWindow("2");
run("Remove Overlay");
save(par1+"\\Marked Skeletons\\"+name);
close("2");
close(name);
res=res+1;
}

IJ.renameResults("GOB","Information for all subsections");
IJ.renameResults("Summary Ben","Subsection summary");



	