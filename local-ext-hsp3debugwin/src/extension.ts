// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
import * as vscode from 'vscode';

// This method is called when your extension is activated
// Your extension is activated the very first time the command is executed
export function activate(context: vscode.ExtensionContext) {

	// now active! - Set HSP3DebugWinButton
	const button = vscode.window.createStatusBarItem(
	  	vscode.StatusBarAlignment.Right, 
	  	0
	);
	button.command = 'vscode-ext.toggleHsp3DebugWin';
	button.tooltip = 'Debugウィンドウ表示設定トグル';
	button.text = 'DebugWin: '+GetStateHSP3DebugWin({});
	context.subscriptions.push(button);
	button.hide();

	// on TabChange! => button.show()/hide();
	let activeEditor = vscode.window.activeTextEditor;
    if (activeEditor) {
        detectTabChange(activeEditor, button);
    }
    vscode.window.onDidChangeActiveTextEditor(editor => {
        activeEditor = editor;
        if (activeEditor) {
            detectTabChange(activeEditor, button);
        }
    });

	// Command : toggleHsp3DebugWin
	vscode.commands.registerCommand('vscode-ext.toggleHsp3DebugWin', () => {
		// andToggle => "language-hsp3.runCommands" -w ON/OFF
		const state = GetStateHSP3DebugWin({andToggle: true});
		if (state === ""){
			button.hide();
			return;
		}
		button.text = 'DebugWin: '+state;
	});
	
}

function GetStateHSP3DebugWin({andToggle = false} : {andToggle?:boolean}){
	// thanks language-hsp3!
	const extensionConfig: vscode.WorkspaceConfiguration = vscode.workspace.getConfiguration('language-hsp3');
	const arr = extensionConfig.get<Array<string>>("runCommands");
	if (arr == null){
		return "";
	}
	if (arr.length != 2){
		return "";
	}
	
	const reg = /^(.*?\-[A-RT-Za-np-vx-z0-9]*)(w?)(.*$)/;
	const divOption = reg.exec(arr[0]);
	if (divOption == null){
		return "";
	}
	if ( divOption[2] == "w" ){
		if (andToggle){
			// Forced update!
			extensionConfig.update("runCommands",[ divOption[1]+divOption[3], arr[1] ], vscode.ConfigurationTarget.Global);
			return "hide";
		}
		return "show";
	}else {
		if (andToggle){
			// Forced update!
			extensionConfig.update("runCommands",[ divOption[1]+"w"+divOption[3], arr[1] ], vscode.ConfigurationTarget.Global);
			return "show";
		}
		return "hide";
	}
}

function detectTabChange(editor: vscode.TextEditor, button: vscode.StatusBarItem) {
	
	if (editor.document.uri.scheme === "output")
		return;
	if (editor.document.languageId === "hsp3"){
		button.show();
		return;
	}
	button.hide();
}

// This method is called when your extension is deactivated
export function deactivate() {}
