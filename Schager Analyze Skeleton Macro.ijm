function blackpixelcount(){
	x=0;
	y=0;
	blackpixel=0;
	run("Select All");
	getRawStatistics(nPixels, mean, min, max, std);
	while (y<getHeight()+1){
		if (getPixel(x,y)>mean){
			blackpixel=blackpixel+1;
		}	
		else if (getPixel(x,y)<mean){
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


dir=getDirectory("Choose a Directory");
dirarray=getFileList(dir);
par1=File.getParent(dir);
par2=File.getParent(par1);
dir2=replace(dir,"skeletons","masks");
dirarray2=getFileList(dir2);
for (i = 0; i < lengthOf(dirarray); i++) {
	open(dir+dirarray[i]);
	run("Clear Results");
	run("Select None");
	//run("Invert");
	name=getTitle();
	run("Remove Overlay");
	run("Set Scale...", "distance=0.8052 known=1 pixel=1 unit=µm");
	run("Select None");
	run("Analyze Skeleton (2D/3D)", "prune=none show");
	selectWindow("Tagged skeleton");
	close();
	jun=0;
	end=0;
	bran=0;
	junv=0;
	trip=0;
	quad=0;
	angle=0;
	for (j = 0; j < nResults; j++) {
		jun=jun+getResult("# Junctions", j);
		end=end+getResult("# End-point voxels", j);
		bran=bran+getResult("# Branches", j);
		junv=junv+getResult("# Junction voxels", j);
		trip=trip+getResult("# Triple points", j);
		quad=quad+getResult("# Quadruple points", j);
		n=n+1;
	}
	IJ.renameResults("Branch information","Results")
	brlen=0;
	eulen=0;
	rulen=0;
	angle=0;
	n=0;
	for (j = 0; j < nResults; j++) {
		brlen=brlen+getResult("Branch length", j);
		eulen=eulen+getResult("Euclidean distance", j);
		rulen=rulen+getResult("running average length", j);
		//a=atan2(getResult("V2 y", j)-getResult("V1 y", j), getResult("V2 x", j)-getResult("V1 x", j))*180/PI;
		b=abs(atan((getResult("V2 y", j)-getResult("V1 y", j))/(getResult("V2 x", j)-getResult("V1 x", j)))*180/PI);
		if (getResult("Euclidean distance", j)!=0){
			angle=angle+b;
			n=n+1;
		}
	}
	//print(angle);
	//print(n);
	angle=angle/n;
	//print(angle);
	run("Clear Results");
	name1=replace(name, ".tif", "");
	//print(par2+"\\ROIs\\"+name1+"_RoiSet.zip");
	if (File.exists(par2+"\\ROIs\\"+name1+"_RoiSet.zip")==1){
		open(par2+"\\ROIs\\"+name1+"_RoiSet.zip");
		roiManager("Select", 0);
	}
	else{
		run("Select All");
	}
	run("Set Measurements...", "area area_fraction redirect=None decimal=9");
	//waitForUser("");
	run("Measure");
	if (File.exists(par2+"\\ROIs\\"+name1+"_RoiSet.zip")==1){
		roiManager("Deselect");
		roiManager("Delete");
	}
	area=getResult("Area", 0);
	parea=getResult("%Area", 0);
	run("Clear Results");
	//len=blackpixelcount();
	//arealen=pow(sqrt(len)*1.242,2);
	//blen=len*1.242;
	close(name);
	if (File.exists(dir2+name)==1)
	{
	open(dir2+name);
	run("Remove Overlay");
	run("Set Scale...", "distance=0.8052 known=1 pixel=1 unit=µm");
	if (File.exists(par2+"\\ROIs\\"+name1+"_RoiSet.zip")==1){
		open(par2+"\\ROIs\\"+name1+"_RoiSet.zip");
		roiManager("Select", 0);
	}
	else{
		run("Select All");
	}
	run("Clear Results");
	run("Set Measurements...", "area area_fraction redirect=None decimal=9");
	//waitForUser("");
	run("Measure");
	rarea=getResult("Area", 0);
	rparea=getResult("%Area", 0);
	run("Clear Results");
	if (File.exists(par1+"\\ROIs\\"+name1+"_RoiSet.zip")==1){
		roiManager("Deselect");
		roiManager("Delete");
	}
	}
	else{
		rarea=0;
		rparea=0;
	}
	if (isOpen("Store")==true){
		IJ.renameResults("Store","Results");
	}
	setResult("File name", i, name);
	setResult("Density (after transformation)", i, ((brlen/1000000)/(rarea*38/1000000000)*1.191)-0.04949);
	setResult("Density (before transformation)", i, (brlen/1000000)/(rarea*38/1000000000));
	setResult("Arc-length", i, brlen);
	setResult("Chord-length", i, eulen);
	setResult("Tortuosity", i, brlen/eulen);
	//setResult("rulen", i, rulen);
	//setResult("area", i, area);
	//setResult("parea", i, parea);
	//setResult("arealen", i, arealen);
	//setResult("blen", i, blen);
	setResult("Junction number", i, jun);
	//setResult("end", i, end);
	setResult("Branch number", i, bran);
	//setResult("junv", i, junv);
	//setResult("trip", i, trip);
	//setResult("quad", i, quad);
	setResult("Average vessel orientation (angle)", i, angle);
	setResult("ROI Area", i, rarea);
	setResult("ROI Area", i, rarea*38);
	setResult("Vessel Area", i, rparea/100*rarea);
	
	setResult("Mean Diameter (approximate FWHM)", i, (rparea/100*rarea)/brlen/2.056);
	//setResult("rparea", i, rparea);
	IJ.renameResults("Results","Store");
	close(name);
}

