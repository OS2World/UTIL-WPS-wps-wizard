/*           Install for WPS-Wizard
 *
 *                   (C) Chris Wohlgemuth 2001-2008
 *
 *  Note that the following license text only applies to this script.
 */
/*
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; see the file COPYING.  If not, write to
 * the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.
 */

 call RxFuncAdd 'SysLoadFuncs', 'RexxUtil', 'SysLoadFuncs'
 call SysLoadFuncs


/* Get the message strings */
nlsStrings.=''
call getStrings


/* Get curent directory */
curdir = directory()


/* Clear screen */
'cls'


/* Check the install phase we are in */
rc=SysIni(, "WPSWizard", "installing")

/* remove trailing '0' */
IF LENGTH(rc)>1 THEN rc=LEFT(rc, 1)


if rc<>"1" THEN DO
	/* First phase */

	SAY ""

	IF haveMMClasses()=0 THEN DO
		/* No CWMM classes */
		/* 'Multimedia classes are not installed. This system configuration is not supported.' */
		/* nlsStrings.22='Press <ENTER> to quit.' */
		SAY ''
		SAY nlsStrings.63
		say ''
		say nlsStrings.22
		say ''
		say '>'
		parse value SysCurPos() with aktzeile aktspalte
		newposition=SysCurPos(aktzeile-1,2)
		pull
		exit
	END


	bootdrive=getBootDrive()

	IF bootdrive<>'' THEN DO
		archfile=bootdrive||"\OS2\ARCHIVES\ARCHIVES.$$$"

		IF doesFileExist(archfile)=1 THEN DO
			archdate=queryCreationDate(archfile)
			diffdate=TRANSLATE("781245", DATE("U"),"12345678")-TRANSLATE("781245", archdate,"12345678")
			IF diffdate>0 THEN DO
				SAY nlsStrings.64 /* 'There is no fresh desktop (WPS) backup available...' */
				SAY ""
				SAY nlsStrings.65 /* 'Go to the 'Archive' page in the settings of the desktop folder...' */
				say ''
				SAY nlsStrings.66 /* 'Enter <y> if you want to install anyway (not recommended).' */
				SAY ""
				say '>'
				parse value SysCurPos() with aktzeile aktspalte
				newposition=SysCurPos(aktzeile-1,2)
				PARSE pull in
				IF TRANSLATE(in)<>'Y' THEN EXIT
			END
		END
	END

	/* Welcome screen */
	SAY ''
	SAY nlsStrings.1 /* 'About to install WPS-Wizard now' */
	/* SAY nlsStrings.2 */ /* '(You did create a desktop backup, did you?)' */
	say ''
	say nlsStrings.3 /* 'Enter <i> to install or any other key to abort.' */
	say ''
	say '>'
	parse value SysCurPos() with aktzeile aktspalte
	newposition=SysCurPos(aktzeile-1,2)
	PARSE pull in
	IF TRANSLATE(in)<>'I' THEN EXIT


	/* Some cleanup... */
	rc=SysIni(, "WPSWizard", "uninstalling", "DELETE:")

	/* Mark that we are installing */
        rc=SysIni(, "WPSWizard", "installing", 1'0'x)
	
	/* 'Current directory is ' */
	say nlsStrings.4||curdir
	say ''

	classdll=curdir'\menufldr.dll'

	/* Register the settings class */
	/* 'Registering class ' */
	say nlsStrings.5||'CWWizzSettings...'
	if SysRegisterObjectClass("CWWizzSettings",classdll)<>1 then
	do	 	
                say ''
		/* 'Error while registering class ' */
		say nlsStrings.6||'CWWizzSettings'
		/* 'Exiting...' */
		say nlsStrings.7
		call unexpectedexit 	
	end 

	/* Register the menu folder class */
	say nlsStrings.5||'CWMenuFolder...'
	if SysRegisterObjectClass("CWMenuFolder",classdll)<>1 then
	do	 	
                say ''
		say nlsStrings.6||'CWMenuFolder'
		/* 'Deregistering class ' */
		say nlsStrings.8||'CWWizzSettings'
		if SysDeregisterObjectClass("CWWizzSettings") <>1 then
			say nlsStrings.9||'CWWizzSettings'
		say nlsStrings.7
		call unexpectedexit 	
	end 

	/* Register the launch area class */
	say nlsStrings.5||'CWLaunchArea...'
	if SysRegisterObjectClass("CWLaunchArea",classdll)<>1 then
	do	 	
                say ''
		say nlsStrings.6||'CWLaunchArea'
		/* 'Deregistering class ' */
		say nlsStrings.8||'CWMenuFolder'
		if SysDeregisterObjectClass("CWMenuFolder") <>1 then
			say nlsStrings.9||'CWMenuFolder'
		/* 'Deregistering class ' */
		say nlsStrings.8||'CWWizzSettings'
		if SysDeregisterObjectClass("CWWizzSettings") <>1 then
			say nlsStrings.9||'CWWizzSettings'
		say nlsStrings.7
		call unexpectedexit 	
	end 

	/* Now install the replacement classes */
	classdll=curdir'\wpswizz.dll'

	/* The replacement object class */
	say nlsStrings.5||'CWObject...'
	if SysRegisterObjectClass("CWObject",classdll)<>1 then
	do	 	
                say ''
		say nlsStrings.6||'CWObject'
		say nlsStrings.8||'CWWizzSettings'
		if SysDeregisterObjectClass("CWWizzSettings") <>1 then
			say nlsStrings.9||'CWWizzSettings'
		say nlsStrings.8||'CWLaunchArea'
		if SysDeregisterObjectClass("CWLaunchArea") <>1 then
			say nlsStrings.9||'CWLaunchArea'
		say nlsStrings.8||'CWMenuFolder'
		if SysDeregisterObjectClass("CWMenuFolder") <>1 then
			say nlsStrings.9||'CWMenuFolder'
		say nlsStrings.7
		call unexpectedexit 	
	end 

	/* Replacing class */
	'bin\repclass WPObject CWObject'
	
	PARSE SOURCE . . theScript

	setupstring="EXENAME="||theScript||";MINIMIZED=NO;MINWIN=HIDE;OBJECTID=<WPSWIZ_INSTALL_PART2>;"
	rc=SysIni(, "PM_InstallObject", "WPS-Wizard installation Part 2;WPProgram;<WP_START>", setupstring)
	rc=SysIni(, "PM_InstallObject", "WPS-Wizard installation Part 2;WPProgram;<WP_START>;UPDATE", "OPEN=DEFAULT")

	say ''
	SAY nlsStrings.60||' '||nlsStrings.61

	say ''
	say nlsStrings.62
	say ''
	say '>'
	parse value SysCurPos() with aktzeile aktspalte
	newposition=SysCurPos(aktzeile-1,2)
	pull

	'@bin\wpsreset.exe'
exit

END /* 1. phase */


/* ******************************************* */
/* Part 2 from here                            */
/* ******************************************* */


SAY "Waiting some seconds for the WPS to load..."
SAY ""

DO a=15 to 1 BY -1
	SAY "..."||a||"..."
	call SysSleep 1
END
SAY ""


call SysDestroyObject "<WPSWIZ_INSTALL_PART2>"
rc=SysIni(, "WPSWizard", "installing", "DELETE:")

	/* 'Current directory is ' */
	say nlsStrings.4||curdir
	say ''

	/* Now install the replacement classes */
	classdll=curdir'\wpswizz.dll'


	/* The replacement folder class */
	say nlsStrings.5||'CWFolder...'
	if SysRegisterObjectClass("CWFolder",classdll)<>1 then
	do	 	
                say ''
		say nlsStrings.6||'CWFolder'
		say nlsStrings.8||'CWObject'
		if SysDeregisterObjectClass("CWObject") <>1 then
			say nlsStrings.9||'CWObject'
		say nlsStrings.8||'CWWizzSettings'
		if SysDeregisterObjectClass("CWWizzSettings") <>1 then
			say nlsStrings.9||'CWWizzSettings'
		say nlsStrings.8||'CWLaunchArea'
		if SysDeregisterObjectClass("CWLaunchArea") <>1 then
			say nlsStrings.9||'CWLaunchArea'
		say nlsStrings.8||'CWMenuFolder'
		if SysDeregisterObjectClass("CWMenuFolder") <>1 then
			say nlsStrings.9||'CWMenuFolder'
		say nlsStrings.7
		call unexpectedexit 	
	end 

	/* The replacement datafile class */
	say nlsStrings.5||'CWDataFile...'
	if SysRegisterObjectClass("CWDataFile",classdll)<>1 then
	do	 	
                say ''
		say nlsStrings.6||'CWDataFile'
		say nlsStrings.8||'CWFolder'
		if SysDeregisterObjectClass("CWFolder") <>1 then
			say nlsStrings.9||'CWFolder'
		say nlsStrings.8||'CWObject'
		if SysDeregisterObjectClass("CWObject") <>1 then
			say nlsStrings.9||'CWObject'
		say nlsStrings.8||'CWWizzSettings'
		if SysDeregisterObjectClass("CWWizzSettings") <>1 then
			say nlsStrings.9||'CWWizzSettings'
		say nlsStrings.8||'CWLaunchArea'
		if SysDeregisterObjectClass("CWLaunchArea") <>1 then
			say nlsStrings.9||'CWLaunchArea'
		say nlsStrings.8||'CWMenuFolder'
		if SysDeregisterObjectClass("CWMenuFolder") <>1 then
			say nlsStrings.9||'CWMenuFolder'
		say nlsStrings.7
		call unexpectedexit 	
	end 

	/* The replacement disk class */
	say nlsStrings.5||'CWDisk...'
	if SysRegisterObjectClass("CWDisk",classdll)<>1 then
	do	 	
                say ''
		say nlsStrings.6||'CWDisk'
		say nlsStrings.8||'CWDataFile'
		if SysDeregisterObjectClass("CWDataFile") <>1 then
			say nlsStrings.9||'CWDataFile'
		say nlsStrings.8||'CWFolder'
		if SysDeregisterObjectClass("CWFolder") <>1 then
			say nlsStrings.9||'CWFolder'
		say nlsStrings.8||'CWObject'
		if SysDeregisterObjectClass("CWObject") <>1 then
			say nlsStrings.9||'CWObject'
		say nlsStrings.8||'CWWizzSettings'
		if SysDeregisterObjectClass("CWWizzSettings") <>1 then
			say nlsStrings.9||'CWWizzSettings'
		say nlsStrings.8||'CWLaunchArea'
		if SysDeregisterObjectClass("CWLaunchArea") <>1 then
			say nlsStrings.9||'CWLaunchArea'
		say nlsStrings.8||'CWMenuFolder'
		if SysDeregisterObjectClass("CWMenuFolder") <>1 then
			say nlsStrings.9||'CWMenuFolder'
		say nlsStrings.7
		call unexpectedexit 	
	end 

	/* The replacement shadow class */
	say nlsStrings.5||'CWShadow...'
	if SysRegisterObjectClass("CWShadow",classdll)<>1 then
	do	 	
                say ''
		say nlsStrings.6||'CWShadow'
		say nlsStrings.8||'CWDisk'
		if SysDeregisterObjectClass("CWDisk") <>1 then
			say nlsStrings.9||'CWDisk'
		say nlsStrings.8||'CWDataFile'
		if SysDeregisterObjectClass("CWDataFile") <>1 then
			say nlsStrings.9||'CWDataFile'
		say nlsStrings.8||'CWFolder'
		if SysDeregisterObjectClass("CWFolder") <>1 then
			say nlsStrings.9||'CWFolder'
		say nlsStrings.8||'CWObject'
		if SysDeregisterObjectClass("CWObject") <>1 then
			say nlsStrings.9||'CWObject'
		say nlsStrings.8||'CWWizzSettings'
		if SysDeregisterObjectClass("CWWizzSettings") <>1 then
			say nlsStrings.9||'CWWizzSettings'
		say nlsStrings.8||'CWLaunchArea'
		if SysDeregisterObjectClass("CWLaunchArea") <>1 then
			say nlsStrings.9||'CWLaunchArea'
		say nlsStrings.8||'CWMenuFolder'
		if SysDeregisterObjectClass("CWMenuFolder") <>1 then
			say nlsStrings.9||'CWMenuFolder'
		say nlsStrings.7
		call unexpectedexit 	
	end 

	/* The theme transient class */
	say nlsStrings.5||'CWThemeTransient...'
	if SysRegisterObjectClass("CWThemeTransient",classdll)<>1 then
	do	 	
                say ''
		say nlsStrings.6||'CWThemeTransient'
		say nlsStrings.8||'CWShadow'
		if SysDeregisterObjectClass("CWShadow") <>1 then
			say nlsStrings.9||'CWShadow'
		say nlsStrings.8||'CWDisk'
		if SysDeregisterObjectClass("CWDisk") <>1 then
			say nlsStrings.9||'CWDisk'
		say nlsStrings.8||'CWDataFile'
		if SysDeregisterObjectClass("CWDataFile") <>1 then
			say nlsStrings.9||'CWDataFile'
		say nlsStrings.8||'CWFolder'
		if SysDeregisterObjectClass("CWFolder") <>1 then
			say nlsStrings.9||'CWFolder'
		say nlsStrings.8||'CWObject'
		if SysDeregisterObjectClass("CWObject") <>1 then
			say nlsStrings.9||'CWObject'
		say nlsStrings.8||'CWWizzSettings'
		if SysDeregisterObjectClass("CWWizzSettings") <>1 then
			say nlsStrings.9||'CWWizzSettings'
		say nlsStrings.8||'CWLaunchArea'
		if SysDeregisterObjectClass("CWLaunchArea") <>1 then
			say nlsStrings.9||'CWLaunchArea'
		say nlsStrings.8||'CWMenuFolder'
		if SysDeregisterObjectClass("CWMenuFolder") <>1 then
			say nlsStrings.9||'CWMenuFolder'
		say nlsStrings.7
		call unexpectedexit 	
	end 

	'bin\repclass WPFolder CWFolder'
	'bin\repclass WPDataFile CWDataFile'
	'bin\repclass WPDisk CWDisk'
	'bin\repclass WPShadow CWShadow'


/*  Create program folder on the desktop: <WPSWIZ_FOLDER> */
/* 'Creating a folder on the desktop...' */
say nlsStrings.10
setupstring='ICONFILE='curdir'\res\wizfol1.ico;ICONNFILE=1,'curdir'\res\wizfol2.ico;OBJECTID=<WPSWIZ_FOLDER>'
if SysCreateObject("WPFolder",nlsStrings.23,"<WP_DESKTOP>",setupstring,"update")<>1 then
             do
                say ''
		/* 'Can''t create the folder.' */
                say nlsStrings.11
		/* 'Exiting...' */
		SAY nlsStrings.7
		call unexpectedexit
             end

/* Create settings object */
setupstring='DEFAULTVIEW=SETTINGS;OBJECTID=<WPSWIZ_SETTINGS>'
/* 'Creating Settings object...' */
say nlsStrings.12
if SysCreateObject("CWWizzSettings",nlsStrings.24, "<WPSWIZ_FOLDER>",setupstring,"update")<>1 then
		do
              say ''
              say nlsStrings.13
              say '' 
            end
setupstring='SHADOWID=<WPSWIZ_SETTINGS>'
if SysCreateObject("WPShadow",nlsStrings.24, "<WP_CONFIG>",setupstring,"update")<>1 then
              say ''

/* Create uninstall object. This object lives in the installation folder not the
   WPS wizard desktop folder to make sure it's not deleted when the uninstall deletes
   the desktop folder. */
say nlsStrings.14
setupstring='EXENAME='curdir'\uninstal.cmd;OBJECTID=<WPSWIZ_UNINSTALL>'
/* Title: "Uninstall^WPS-Wizzard" */
if SysCreateObject("WPProgram",nlsStrings.25, curdir,setupstring,"update")<>1 then
              say nlsStrings.15

/* Create a shadow in the desktop folder */
setupstring='SHADOWID=<WPSWIZ_UNINSTALL>'
if SysCreateObject("WPShadow",nlsStrings.25, "<WPSWIZ_FOLDER>",setupstring,"update")<>1 then
              say nlsStrings.15

/* Create tutorial object */
/* 'Creating an object for the tutorial in the folder...' */
say nlsStrings.16
setupstring='EXENAME=view.exe;PARAMETERS='curdir'\Help\menuwizz.inf;OBJECTID=<WPSWIZ_TUTORIAL>'
if SysCreateObject("WPProgram",nlsStrings.26, "<WPSWIZ_FOLDER>",setupstring,"update")<>1 then
              say nlsStrings.17

/* 'Creating default configuration folders...' */
SAY nlsStrings.19
setupstring='DEFAULTVIEW=TREE;SHOWALLINTREEVIEW=YES;OBJECTID=<WPSWIZ_CONFIG>'
if SysCreateObject("WPFolder",nlsStrings.34,"<WPSWIZ_FOLDER>",setupstring,"update")<>1 then
             do
                say ''
		/* 'Can''t create the folder.' */
                say nlsStrings.11
		/* 'Exiting...' */
		SAY nlsStrings.7
		call unexpectedexit
             end

/*  */
/* Create default configuration folders */
createskript=curdir'\bin\createdf.cmd'
rc=SysSetObjectData(createskript, "OPEN=DEFAULT")
createskript=curdir'\bin\createfd.cmd'
rc=SysSetObjectData(createskript, "OPEN=DEFAULT")

/* Create folder for menu templates */
say nlsStrings.20
setupstring='ICONFILE='curdir'\res\templ1.ico;ICONNFILE=1,'curdir'\res\templ2.ico;OBJECTID=<MENUITEMS_FOLDER>'
if SysCreateObject("WPFolder",nlsStrings.28,"<WPSWIZ_FOLDER>",setupstring,"update")<>1 then
             do
                say ''
                say nlsStrings.11
		SAY nlsStrings.7
		call unexpectedexit
             end

/* Create menu folder template */
say nlsStrings.18
setupstring='TEMPLATE=YES'
if SysCreateObject("CWMenuFolder",nlsStrings.27, "<MENUITEMS_FOLDER>",setupstring,"update")<>1 then
             do
                say ''
                say nlsStrings.11
             end

/* Create menu items */
say nlsStrings.32
setupstring='EXENAME='curdir'\bin\copyname.exe;PARAMETERS="%*";MINIMIZED=YES;MINVIEW=HIDE;CCVIEW=YES;TEMPLATE=YES'
if SysCreateObject("WPProgram",nlsStrings.29,"<MENUITEMS_FOLDER>",setupstring,"update")<>1 then
              say nlsStrings.21
setupstring='EXENAME='curdir'\bin\zipthis.cmd;PARAMETERS="%*";MINVIEW=HIDE;CCVIEW=YES;TEMPLATE=YES;ICONFILE='curdir'\Res\MWDAT.ico'
if SysCreateObject("WPProgram",nlsStrings.30,"<MENUITEMS_FOLDER>",setupstring,"update")<>1 then
              say nlsStrings.21
/*setupstring='EXENAME='curdir'\bin\ziptree.cmd;PARAMETERS="%*";MINIMIZED=YES;MINVIEW=HIDE;CCVIEW=YES'*/
/* Zip this tree */
setupstring='EXENAME='curdir'\bin\ziptree.cmd;MINVIEW=HIDE;CCVIEW=YES;TEMPLATE=YES;ICONFILE='curdir'\Res\MWFOL.ico'
if SysCreateObject("WPProgram",nlsStrings.31,"<MENUITEMS_FOLDER>",setupstring,"update")<>1 then
              say nlsStrings.21



/*-------- Create toolbar objects --------*/

/* Create folder for folder actions */
say nlsStrings.35
setupstring='OBJECTID=<WPSWIZ_TBITEMFOLDER>'
if SysCreateObject("WPFolder",nlsStrings.36,"<WPSWIZ_FOLDER>",setupstring,"update")<>1 then
             do
                say ''
                say nlsStrings.11
             end

/* Now create all the folder action objects */

/* Open parent */
setupstring='EXENAME='curdir'\bin\toolbar\parent.cmd;MINIMIZED=YES;MINVIEW=HIDE;CCVIEW=YES;ICONFILE='curdir'\res\parent.ico;OBJECTID=<WPSWIZ_TBIOPENPARENT>;'
if SysCreateObject("WPProgram",nlsStrings.37,"<WPSWIZ_TBITEMFOLDER>",setupstring,"update")<>1 then
              say nlsStrings.44||nlsStrings.37

/* Settings */
setupstring='EXENAME='curdir'\bin\toolbar\settings.cmd;MINIMIZED=YES;MINVIEW=HIDE;CCVIEW=YES;ICONFILE='curdir'\res\properties.ico;OBJECTID=<WPSWIZ_TBISETTINGS>;'
if SysCreateObject("WPProgram",nlsStrings.38,"<WPSWIZ_TBITEMFOLDER>",setupstring,"update")<>1 then
              say nlsStrings.44||nlsStrings.38

/* OS/2 command window */
setupstring='EXENAME='curdir'\bin\toolbar\cmdwin.cmd;CCVIEW=YES;OBJECTID=<WPSWIZ_TBICMDWIN>;'
if SysCreateObject("WPProgram",nlsStrings.39,"<WPSWIZ_TBITEMFOLDER>",setupstring,"update")<>1 then
              say nlsStrings.44||nlsStrings.39

/* OS/2 command window wide */
setupstring='EXENAME='curdir'\bin\toolbar\widecmd.cmd;MINVIEW=HIDE;CCVIEW=YES;OBJECTID=<WPSWIZ_TBICMDWINWIDE>;'
if SysCreateObject("WPProgram",nlsStrings.40,"<WPSWIZ_TBITEMFOLDER>",setupstring,"update")<>1 then
              say nlsStrings.44||nlsStrings.40

/* Refresh */
setupstring='EXENAME='curdir'\bin\toolbar\refresh.cmd;MINIMIZED=YES;MINVIEW=HIDE;CCVIEW=YES;ICONFILE='curdir'\res\refresh.ico;OBJECTID=<WPSWIZ_TBIREFRESH>;'
if SysCreateObject("WPProgram",nlsStrings.41,"<WPSWIZ_TBITEMFOLDER>",setupstring,"update")<>1 then
              say nlsStrings.44||nlsStrings.41

/* Details view */
setupstring='EXENAME='curdir'\bin\toolbar\details.cmd;MINIMIZED=YES;MINVIEW=HIDE;CCVIEW=YES;ICONFILE='curdir'\res\details.ico;OBJECTID=<WPSWIZ_TBIDETAILS>;'
if SysCreateObject("WPProgram",nlsStrings.42,"<WPSWIZ_TBITEMFOLDER>",setupstring,"update")<>1 then
              say nlsStrings.44||nlsStrings.42

/* Icon view */
setupstring='EXENAME='curdir'\bin\toolbar\icon.cmd;MINIMIZED=YES;MINVIEW=HIDE;CCVIEW=YES;ICONFILE='curdir'\res\icon.ico;OBJECTID=<WPSWIZ_TBIICON>'
if SysCreateObject("WPProgram",nlsStrings.43,"<WPSWIZ_TBITEMFOLDER>",setupstring,"update")<>1 then
              say nlsStrings.44||nlsStrings.43

/* OS/2 full screen */
setupstring='EXENAME='curdir'\bin\toolbar\cmdfull.cmd;MINIMIZED=YES;MINVIEW=HIDE;CCVIEW=YES;ICONFILE='curdir'\res\cmdfull.ico;OBJECTID=<WPSWIZ_TBICMDFULL>'
if SysCreateObject("WPProgram",nlsStrings.47,"<WPSWIZ_TBITEMFOLDER>",setupstring,"update")<>1 then
              say nlsStrings.44||nlsStrings.47

/* Select all */
setupstring='EXENAME='curdir'\bin\toolbar\selall.cmd;MINIMIZED=YES;MINVIEW=HIDE;CCVIEW=YES;ICONFILE='curdir'\res\program.ico;OBJECTID=<WPSWIZ_TBISELECTALL>'
if SysCreateObject("WPProgram",nlsStrings.48,"<WPSWIZ_TBITEMFOLDER>",setupstring,"update")<>1 then
              say nlsStrings.44||nlsStrings.48

/* Deselect all */
setupstring='EXENAME='curdir'\bin\toolbar\deselall.cmd;MINIMIZED=YES;MINVIEW=HIDE;CCVIEW=YES;ICONFILE='curdir'\res\program.ico;OBJECTID=<WPSWIZ_TBIDESELECTALL>'
if SysCreateObject("WPProgram",nlsStrings.49,"<WPSWIZ_TBITEMFOLDER>",setupstring,"update")<>1 then
              say nlsStrings.44||nlsStrings.49


/*** Create default folder action area ***/
setupstring='NOTVISIBLE=NO;OBJECTID=<WPSWIZ_FLDRACTION>;'
if SysCreateObject("CWLaunchArea", "fldraction", curdir ,setupstring,"replace")<>1 then
              say nlsStrings.44||nlsStrings.45
rc=SysSetObjectData("<WPSWIZ_FLDRACTION>", "FPOBJECTS=<WPSWIZ_TBIOPENPARENT>,<WPSWIZ_TBISETTINGS>,<WPSWIZ_TBIICON>,<WPSWIZ_TBIDETAILS>,<WPSWIZ_TBIREFRESH>,<WPSWIZ_TBICMDWINWIDE>;")

/*** Create default folder launchpad ***/
setupstring='NOTVISIBLE=NO;OBJECTID=<WPSWIZ_FLDRLAUNCHPAD>;'
if SysCreateObject("CWLaunchArea", "fldrlaunchpad", curdir ,setupstring,"replace")<>1 then
              say nlsStrings.44||nlsStrings.46
rc=SysSetObjectData("<WPSWIZ_FLDRLAUNCHPAD>", "FPOBJECTS=<WPSWIZ_SETTINGS>,<WPSWIZ_FOLDER>,<WPSWIZ_TUTORIAL>,<WP_DRIVES>,<WP_CONFIG>;")



/* Create gadget folder */
say nlsStrings.51
setupstring='ICONFILE='curdir'\res\gadfol1.ico;ICONNFILE=1,'curdir'\res\Gadfol2.ico;OBJECTID=<WPSWIZ_GADGETFOLDER>'
if SysCreateObject("WPFolder",nlsStrings.50,"<WPSWIZ_FOLDER>",setupstring,"update")<>1 then
             do
                say ''
                say nlsStrings.11
             end

/* Now create all the gadget objects */
/* Time gadget */
setupstring='EXENAME='curdir'\bin\gadgets\timegadget.cmd;MINIMIZED=YES;MINVIEW=HIDE;CCVIEW=YES;ICONFILE='curdir'\res\program.ico;OBJECTID=<WPSWIZ_TIMEGADGET>;'
if SysCreateObject("WPProgram",nlsStrings.52,"<WPSWIZ_GADGETFOLDER>",setupstring,"update")<>1 then
              say nlsStrings.44||nlsStrings.52

/* System information  gadget */
setupstring='EXENAME='curdir'\bin\gadgets\sysinfo.cmd;MINIMIZED=YES;MINVIEW=HIDE;CCVIEW=YES;ICONFILE='curdir'\res\program.ico;OBJECTID=<WPSWIZ_SYSINFOGADGET>;'
if SysCreateObject("WPProgram",nlsStrings.53,"<WPSWIZ_GADGETFOLDER>",setupstring,"update")<>1 then
              say nlsStrings.44||nlsStrings.53

/* Drive information  gadget */
setupstring='EXENAME='curdir'\bin\gadgets\driveinfo.cmd;MINIMIZED=YES;MINVIEW=HIDE;CCVIEW=YES;ICONFILE='curdir'\res\program.ico;OBJECTID=<WPSWIZ_DRIVEINFOGADGET>;'
if SysCreateObject("WPProgram",nlsStrings.54,"<WPSWIZ_GADGETFOLDER>",setupstring,"update")<>1 then
              say nlsStrings.44||nlsStrings.54

/* z!-info  gadget */
setupstring='EXENAME='curdir'\bin\gadgets\z-info.cmd;MINIMIZED=YES;MINVIEW=HIDE;CCVIEW=YES;ICONFILE='curdir'\res\program.ico;OBJECTID=<WPSWIZ_ZINFOGADGET>;'
if SysCreateObject("WPProgram",nlsStrings.55,"<WPSWIZ_GADGETFOLDER>",setupstring,"update")<>1 then
              say nlsStrings.44||nlsStrings.55

/* Month gadget */
setupstring='EXENAME='curdir'\bin\gadgets\monthGadget.cmd;MINIMIZED=YES;MINVIEW=HIDE;CCVIEW=YES;ICONFILE='curdir'\res\program.ico;OBJECTID=<WPSWIZ_MONTHGADGET>;'
if SysCreateObject("WPProgram",nlsStrings.56,"<WPSWIZ_GADGETFOLDER>",setupstring,"update")<>1 then
              say nlsStrings.44||nlsStrings.56

/* File monitor gadget */
setupstring='EXENAME='curdir'\bin\gadgets\filemonGadget.cmd;MINIMIZED=YES;MINVIEW=HIDE;CCVIEW=YES;ICONFILE='curdir'\res\program.ico;OBJECTID=<WPSWIZ_FILEMONGADGET>;'
if SysCreateObject("WPProgram",nlsStrings.57,"<WPSWIZ_GADGETFOLDER>",setupstring,"update")<>1 then
              say nlsStrings.44||nlsStrings.57

/* Binary clock gadget */
setupstring='EXENAME='curdir'\bin\gadgets\binaryclockGadget.cmd;MINIMIZED=YES;MINVIEW=HIDE;CCVIEW=YES;ICONFILE='curdir'\res\program.ico;OBJECTID=<WPSWIZ_BINARYCLOCKGADGET>;'
if SysCreateObject("WPProgram",nlsStrings.58,"<WPSWIZ_GADGETFOLDER>",setupstring,"update")<>1 then
              say nlsStrings.44||nlsStrings.58


classdll=curdir'\mmtheme.dll'

say nlsStrings.5||'CWThemeMMImage...'
if SysRegisterObjectClass("CWThemeMMImage",classdll)<>1 then
	do	 	
                say ''
		/* 'Error while registering class ' */
		say nlsStrings.6||'CWThemeMMImage'
	end 

'bin\repclass MMImage CWThemeMMImage'

/********    Done    ********/
say ''
say nlsStrings.22
SAY nlsStrings.33
say ''
say '>'
parse value SysCurPos() with aktzeile aktspalte
newposition=SysCurPos(aktzeile-1,2)
pull

/* 'bin\wpsreset.exe' */

exit


/*-------------------------------------------------------------------------*/
unexpectedExit:

rc=SysIni(, "WPSWizard", "installing", "DELETE:")
say ''
say nlsStrings.59
say ''
say nlsStrings.22
say ''
say '>'
parse value SysCurPos() with aktzeile aktspalte
newposition=SysCurPos(aktzeile-1,2)
pull
exit


/*-------------------------------------------------------------------------*/
/* Check if running on eCS1.2 or later. Will succeed
 on Warp 4 with installed CWMM classes, too. */
haveMMClasses: procedure

  ret=SysQueryClassList('classes.')
  found=0
  DO cls=1 to classes.0
	theclass=WORD(classes.cls, 1)
	thePath=SUBWORD(classes.cls, 2);
	IF TRANSLATE(theClass)='CWMMDATAFILE' THEN DO;
		found=1	;
		LEAVE;
	END;
  END;
return found

/*-------------------------------------------------------------------------*/
doesFileExist: procedure

IF STREAM(ARG(1),'c', 'query exists')<>'' THEN return 1

return 0

/*-------------------------------------------------------------------------*/
/* returns the creation date in format month/day/year e.g. 02/15/08 */
queryCreationDate: procedure

rc= SYSFileTree(arg(1), file, 'F')

if file.0=1 THEN DO
	PARSE VAR file.1 dat rest

	dat=RIGHT(dat, 8, 0)
	drop file.
	return dat
END

return ""

/*-------------------------------------------------------------------------*/
/* Query bootdrive */
GetBootDrive: procedure
parse upper value VALUE('PATH',,'OS2ENVIRONMENT') with '\OS2\INSTALL' -2 boot +2
parse upper value VALUE('PATH',,'OS2ENVIRONMENT') with '\OS2\SYSTEM' -2 boot2 +2

if boot=boot2 then return boot

return ''

/*-------------------------------------------------------------------------*/
/**** The following subroutine was appended while building the distribution:

GetStrings:
nlsStrings.1="..."
...
return

The routine adds the NLS strings to this script. For creating other NLS-versions
translate the files in /nls and change the makefile to include the new NLS-version.
*/
