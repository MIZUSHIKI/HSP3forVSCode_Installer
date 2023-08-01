#include "user32.as"
#include "kernel32.as"
#ifndef _load_dll_
#define _load_dll_
#module load_dll
#deffunc load_dll_init
	sdim name, 261
	GetModuleFileNameA 0, varptr(name), 260
	LoadLibraryA getpath(name, 8)
	hEXE = stat
	GetProcAddress hEXE, "InitializeDLLLoad"
	pInitializeDLLLoad = stat
	if pInitializeDLLLoad == 0{
		dialog "hsp3ld�����^�C�����g�p����Ă��܂���B�I�����܂��B" : end
	}
	prm = 0
	ret = callfunc(prm, pInitializeDLLLoad, 0)
return ret
#deffunc LoadDLL str fname
	name = getpath(fname, 8) + "_DLLIMAGE"
	exist fname
	if strsize == -1 : return 0
	size = strsize
	sdim buf, size
	bload fname, buf
	// DLL�C���[�W����������
	// PAGE_READWRITE
	CreateFileMapping -1, 0, 0x04, 0, size, 0; varptr(name)
	hMapObj = stat
	// FILE_MAP_WRITE
	MapViewOfFile hMapObj, 0x02, 0, 0, size
	sharedMemPtr = stat
	if sharedMemPtr == 0 {
		CloseHandle hMapObj
		return 0
	}
	dupptr sharedMemVal, sharedMemPtr, size, 2
	// DLL�C���[�W���R�s�[����
	memcpy sharedMemVal, buf, size, 0, 0
	UnmapViewOfFile sharedMemPtr	// ��x���Ă���
	// FILE_MAP_READ
	MapViewOfFile hMapObj, 0x04, 0, 0, 0
	pBaseAddr = stat
	if pBaseAddr == 0{
		CloseHandle hMapObj
		return 0
	}	
	// ���s
	name = getpath(fname, 8)
	GetProcAddress hEXE, "LoadDLLFromImage"
	pLoadDLLFromImage = stat
	prm.0 = pBaseAddr, varptr(name), 0
	ret = callfunc(prm, pLoadDLLFromImage, 3)
	
	UnmapViewOfFile pBaseAddr
	CloseHandle hMapObj
return ret
#defcfunc GetDLLProcAddress int handle, str fn
	_fn = fn
	GetProcAddress hEXE, "GetDLLProcAddress"
	pGetDLLProcAddress = stat
	prm = handle, varptr(_fn)
	ret = callfunc(prm, pGetDLLProcAddress, 2)
return ret
#deffunc LoadPackDLL str _fname
	// �������ɕϊ�
	fname = getpath(_fname, 16)
	// ���łɓǂݍ��ݍς݂ȏꍇ��DLL���f�^�b�`����
	GetModuleHandle fname
	if stat != 0{
		FreeLibrary stat
	}
	// �p�b�N�t�@�C������DLL��ǂݎ��A�^�b�`����
	LoadDLL fname
	hDLL = stat
	if hDLL == 0 : return -1	// ���s 
	
	// Func info ���� �֐����������č����ւ��o�^����
	mref hspctx, 68
	dupptr hsphed, hspctx.0, 96 // hspctx.hsphed / sizeof HSPHED
	ds_ptr = lpeek( hspctx, 12 ) // hspctx.mem_mds
	finfo_ptr = lpeek( hspctx, 840 ) // hspctx.mem_finfo
	max_finfo = lpeek( hsphed, 60 ) // hsphed.max_finfo
	linfo_ptr = lpeek( hspctx, 840 - 8 )
	max_linfo = lpeek( hsphed, 60 - 8 )
	
	dupptr linfo, linfo_ptr, max_linfo
	sdim dlllist, 260 : dllnum = 0	// �g�p����DLL���̃��X�g�ł���
	for i, 0, max_linfo, 16	// LIBDAT size
		nameidx = lpeek( linfo, i + 4 )
		dupptr dllname, ds_ptr + nameidx, 260, 2
		dlllist.dllnum = getpath(dllname, 16)	// ��������
		dllnum++
		sdim dllname
	next
	sdim linfo
	// �֐����̈ꗗ�ł���
	dupptr finfo, finfo_ptr, max_finfo
	for i, 0, max_finfo, 28 // sizeof STRUCTDAT == 28
		libindex = wpeek( finfo, i)
		nameidx = lpeek( finfo, i + 12 )
		proc = lpeek( finfo, i + 24 )
		dupptr name, ds_ptr + nameidx, 260, 2
		if dllnum > libindex {
			// DLL���̈�v
			if dlllist(libindex) == fname{
				// �֐�������A�h���X���擾
				pFunc = GetDLLProcAddress(hDLL, name)
				if pFunc == 0 : _continue
				// ��������
				lpoke finfo, i + 24, pFunc
			}
			;logmes name + ":"+proc+":"+dlllist(libindex)
		}
		sdim name
	next
	sdim finfo
	sdim hsphed
return 0
#deffunc LoadPackHPI str _fname
	// �������ɕϊ�
	fname = getpath(_fname, 16)
	
	// ���łɓǂݍ��ݍς݂ȏꍇ��DLL���f�^�b�`����
	GetModuleHandle fname
	if stat != 0{
		FreeLibrary stat
	}
	// �p�b�N�t�@�C������DLL��ǂݎ��A�^�b�`����
	LoadDLL fname
	hDLL = stat
	if hDLL == 0 : return -1	// ���s 
	
	mref hspctx, 68
	dupptr hsphed, hspctx.0, 96 // hspctx.hsphed / sizeof HSPHED
	ds_ptr = lpeek( hspctx, 12 ) // hspctx.mem_mds
	;dupptr ds, ds_ptr, 1024
	;bsave "ds.txt", ds, 1024
	
	pt_hpidat = lpeek( hsphed, 80 )
	max_hpi = wpeek( hsphed, 84 )
	max_varhpi = wpeek( hsphed, 86 )
	ptr = hspctx.0 + pt_hpidat
	
	dupptr hpidat, ptr, max_hpi
	for i, 0, max_hpi, 16	// HPIDAT size
		nameidx = lpeek( hpidat, i + 4 )
		funcidx = lpeek( hpidat, i + 8 )
		;_libptr = lpeek( hpidat, i + 12 )
		dupptr funcname, ds_ptr + funcidx, 260, 2
		dupptr name, ds_ptr + nameidx, 260, 2
		dllname = getpath(name, 16)
		// DLL���̈�v
		if dllname == fname{
			pFunc = GetDLLProcAddress(hDLL, funcname)
			if pFunc == 0 : _continue
			lpoke hpidat, i + 12, pFunc
		}
		sdim name
		sdim funcname
	next
	sdim hpidat
	;sdim ds
	sdim hsphed
return 0
#deffunc KillDLLLoad onexit
	GetProcAddress hEXE, "KillDLLLoad"
	pKillDLLLoad = stat
	prm = 0
	ret = callfunc(prm, pKillDLLLoad, 0)
return
#global
load_dll_init
#endif