dir=File.directory;
name=File.name;
directarray=getFileList(dir);
par1=File.getParent(dir);
if (File.exists(par1+"\\Vessel Macro Output")==0){
	File.makeDirectory(par1+"\\Vessel Macro Output");
}
if (File.exists(par1+"\\ROIs")==0){
	File.makeDirectory(par1+"\\ROIs");
}
for (i=0; i<lengthOf(directarray); i++){
	name=File.name;
	rawName=replace(name,".tif","");
	nROIs=roiManager("count");
	if (nROIs!=0){
		roiManager("Select",0);
		roiManager("Deselect");
		roiManager("Delete");
	}
	run("Z Project...", "projection=[Max Intensity]");
	waitForUser("Define ROI, then hit OK. Hit Esc if you no longer want to draw ROIs.");
	roiManager("Add");
	roiManager("Select",0);
	run("Make Inverse");
	roiManager("Add");
	roiManager("Save",par1+"\\ROIs\\"+rawName+"_RoiSet.zip");
	selectWindow(name);
	run("Open Next");
	close("MAX_"+name);
	
	
}

