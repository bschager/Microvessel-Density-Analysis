//This macro takes opens a skeleton (defined by a name ending in "_skeleton1.tif") and divides it into 170x170 pixels subsections
//it deletes parts of the box that are not in the ROI, and reports the length density of the skeleton in subsections greater than 1/3 the maximum subsection ROI area
//macro is designed to be run on the output folder of Schager_v6 Vessel Density Plugin.ijm
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
dir=File.directory;
directarray=getFileList(dir);
name=getTitle;
close(name);

stds=newArray();
names=newArray();
res=0;

for(z=0; z<lengthOf(directarray); z++)
{
extension=substring(directarray[z],lengthOf(directarray[z])-6,lengthOf(directarray[z])-4);

if (extension=="n1")
{
open(dir+directarray[z]);
name=getTitle;
rawName=replace(name,"_skeleton1.tif","");
par1=File.getParent(dir);
run("Remove Overlay");
nROIs = roiManager("count");
if (nROIs!=0){
	roiManager("Select", 0);
	roiManager("Deselect");
	roiManager("Delete");
}
open(par1+"\\ROIs\\"+rawName+"_RoiSet.zip");
nROIstart = roiManager("count");

divideROIs();

run("Clear Results");
run("Set Measurements...", "area area_fraction redirect=None decimal=9");
run("Select None");

areas=newArray();
perAreas=newArray();

roiManager("Select", 0);
run("Measure");

for (i=0 ; i<nROIstart; i++) {
	roiManager("Select", 0);
	roiManager("Delete");
}

nROIs=roiManager("count");
for (i=0; i<nROIs; i++) {	
	roiManager("Select", i);
	getStatistics(area);
	if (area>1/3*44580.2){
		run("Measure");
	}
}
totalArea=getResult("Area",0);
totalPerArea=getResult("%Area",0);

for (i=1; i<nResults; i++){
	areas=Array.concat(areas,getResult("Area",i));
	perAreas=Array.concat(perAreas,getResult("%Area",i));
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
setResult("Total PerArea", res, totalPerArea);
for (i=0; i<lengthOf(areas);i++){
	setResult("Area "+i, res,areas[i]);
	setResult("perArea "+i, res,perAreas[i]);
}
IJ.renameResults("Results","GOB");
res=res+1;
close(name);
}
}





	