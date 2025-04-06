; #Requires AutoHotkey v2+
; #Include <Includes\ObjectTypeExtensions>

;@class Gui2
Gui.Prototype.Base := Gui2

class Gui2 {

	#Requires AutoHotkey v2+

	static WS_EX_NOACTIVATE 	:= '0x08000000L'
	static WS_EX_TRANSPARENT 	:= '0x00000020L'
	static WS_EX_COMPOSITED 	:= '0x02000000L'
	static WS_EX_CLIENTEDGE 	:= '0x00000200L'
	static WS_EX_APPWINDOW 		:= '0x00040000L'
	static WS_EX_LAYERED      	:= '0x00080000L'  ; Layered window for transparency
	static WS_EX_TOOLWINDOW   	:= '0x00000080L'  ; Creates a tool window (no taskbar button)
	static WS_EX_TOPMOST      	:= '0x00000008L'  ; Always on top
	static WS_EX_ACCEPTFILES  	:= '0x00000010L'  ; Accepts drag-drop files
	static WS_EX_CONTEXTHELP  	:= '0x00000400L'  ; Has '?' button in titlebar


	static __New() {
		; Add all Gui2 methods to Gui prototype
		for methodName in Gui2.OwnProps() {
			if methodName != "__New" && HasMethod(Gui2, methodName) {
				; Check if method already exists
				if Gui.Prototype.HasOwnProp(methodName) {
					; Either skip, warn, or override based on your needs
					continue  ; Skip if method exists
					; Or override:
					; Gui.Prototype.DeleteProp(methodName)
				}
				Gui.Prototype.DefineProp(methodName, {
					Call: Gui2.%methodName%
				})
			}
		}
	}

	static Layered() => this.MakeLayered()
	static ToolWindow() => this.MakeToolWindow()
	static AlwaysOnTop() => this.SetAlwaysOnTop()
	static AppWindow() => this.ForceTaskbarButton()
	static Transparent() => this.MakeClickThrough()
	static NoActivate() => this.PreventActivation()
	static NeverFocusWindow() => this.NoActivate()

	; static DarkMode(guiObj := this, BackgroundColor := '') {
	; static DarkMode(BackgroundColor := '') {
	; 	guiObj := this
	; 	if (guiObj is Gui) {
	; 		if (BackgroundColor = '') {
	; 			guiObj.BackColor := '0xA2AAAD'
	; 		} else {
	; 			guiObj.BackColor := BackgroundColor
	; 		}
	; 	}
	; 	return this
	; }
	;; @method static DarkMode(params*)
	static DarkMode(params*) {
		
		; Default background color
		; static backgroundColor := '0xA2AAAD'
		static backgroundColor := unset
		; guiObj := this
		static hexNeedle := '\b[0-9A-Fa-f]+\b'
		
		; Parse params array
		for param in params {

			if (param is Gui){
				guiObj := param
			}
			else if IsObject(param){
				continue    ; Skip other object types
			}
			else {
				; backgroundColor := param
				if !IsSet(backgroundColor) {
					if param ~= hexNeedle {
						backgroundColor := param
					}
					else {
						backgroundColor := '0xA2AAAD'
					}
				}
			}
		}
		
		if !IsSet(guiObj) {
			guiObj := this
		}
		if !IsSet(backgroundColor) {
			backgroundColor := '0xA2AAAD'
		}
		; Apply background color 
		if (guiObj is Gui){
			guiObj.BackColor := backgroundColor
		}

		; infos(backgroundColor)

		return guiObj
	}

	/**
	 * @description Improves font settings with reasonable defaults and parameter parsing
	 * @param {String} options Optional font settings string containing:
	 *                        - Font size: "s12" or just "12"
	 *                        - Quality: "Q5" (0-5)
	 *                        - Color: "cFF0000" or "c0xFF0000"
	 * @param {String} nFont Optional font name (default: "Consolas")
	 * @returns {Gui} The Gui object for method chaining
	 * @example
	 * ; Using defaults (s12 Q5 c1eff00 Consolas)
	 * gui.MakeFontNicer()
	 * 
	 * ; Setting just size
	 * gui.MakeFontNicer("14")             
	 * 
	 * ; Size and quality
	 * gui.MakeFontNicer("s16 Q4")         
	 * 
	 * ; Full specification
	 * gui.MakeFontNicer("s12 Q5 cFF0000") 
	 * 
	 * ; Different font
	 * gui.MakeFontNicer("s10", "Arial")   
	 */

	static MakeFontNicer(params*) {

		; Define font characteristics as UnSet to allow setting defaults after parsing the params
		static fontName := color := quality := size := unset
		static hexNeedle := '\b[0-9A-Fa-f]+\b'
		
		; Default background color
		static backgroundColor := unset
		
		if params is Gui {
			guiObj := params
		}
	
		

		if !IsSet(guiObj) {
			guiObj := this
		}

		; Parse params
		for param in params {
			par .= param
			if param is Array {
				aParams := param.Clone()
				for cParam in aParams {
					paramsParser(cParam)
				}
				continue
			}
			if param is String {
				paramsParser(param)
			}
		}
		; MsgBox(par)
		paramsParser(parameter) {
			
			if (parameter is Gui) {
				guiObj := parameter
				return
			}
			; infos('parameter:' parameter)
			; Font size with 's' prefix
			if parameter ~= 'i)^s[\d]+' {
				size := SubStr(parameter, 2)  ; Remove 's' prefix
				try guiObj.SetFont('s' size)
				; return
			}
			; Font size without prefix
			if parameter ~= 'i)([^q])[\d]+' || parameter ~= '^[\d]+'{
				size := parameter
				try guiObj.SetFont('s' size)
				; return
			}
			; Quality setting
			if parameter ~= 'i)^q[\d]+' {
				quality := parameter
				try guiObj.SetFont(quality)
				; return
			}
			; Color handling - support both named colors and hex
			if parameter ~= 'i)^c[\w\d]+' {
				color := parameter  ; Direct color format (e.g., cBlue)
				try guiObj.SetFont(color)
				; return
			}
			if parameter ~= hexNeedle {
				color := 'c' parameter  ; Add 'c' prefix for hex colors
				try guiObj.SetFont(color)
				; return
			}
			; Font name - anything that starts with letter and contains word chars or spaces
			if parameter ~= '^[a-zA-Z][\w\s-]*$' {
				fontName := parameter
				try guiObj.SetFont(, fontName)
			}
		}

		; Set defaults for unset parameters
		; if !IsSet(guiObj) {
		; 	guiObj := this
		; }
		; s := q := c := f := ''
		; IsSet(size)?size:s:='size: unset', IsSet(quality)?quality:q:='quality: unset', IsSet(color)?color:c:='color: unset', IsSet(fontName)?fontName:f:='size: unset'
		; MsgBox(par '`n' s ' ' q ' ' c ' ' f)
		
		if !IsSet(size) {
			size := 20
		}
		if !IsSet(quality) {
			quality := 'Q5'
		}
		if !IsSet(color) {
			color := 'cBlue'
		}
		if !IsSet(fontName) {
			fontName := 'Consolas'
		}
	
		; Build font options string
		options := 's' size ' ' quality ' ' color
		; Infos('options: ' options)
		; Apply font settings based on context
		if (guiObj is Gui) {
			; Infos('I am a Gui')
			; ToolTip('I am a ' Type(guiObj))
			guiObj.SetFont(options, fontName)
		}
		; else if Type(guiObj) = "Class" {
		; 	; Infos('I am a Class')
		; 	guiObj.SetFont(options, fontName)
		; }
		
		return guiObj
	}

	
	/**
	 * @description Prevents window from receiving focus or being activated
	 * @returns {Gui} The Gui object for method chaining
	 * @example
	 * gui.NoActivate()
	*/
	static PreventActivation() {
		WinSetExStyle('+' this.WS_EX_NOACTIVATE, this)
		return this
	}

	; static NeverFocusWindow(guiObj := this) {
	; static NeverFocusWindow() {
	; 	; guiObj := guiObj ? guiObj : this
	; 	; WinSetExStyle('+' this.NOACTIVATE, guiObj)
	; 	WinSetExStyle('+' this.WS_EX_NOACTIVATE, this)
	; 	; WinSetExStyle('+' . this.TRANSPARENT, guiObj)
	; 	; WinSetExStyle('+' . this.COMPOSITED, guiObj)
	; 	; WinSetExStyle('+' . this.CLIENTEDGE, guiObj)
	; 	; WinSetExStyle('+' . this.APPWINDOW, guiObj)
	; 	; return guiObj
	; 	return this
	; }

	/**
	 * @description Makes window click-through (input passes to windows beneath)
	 * @returns {Gui} The Gui object for method chaining
	 * @example
	 * gui.MakeClickThrough()
	 */
	static MakeClickThrough() {
		WinSetExStyle('+' this.WS_EX_TRANSPARENT, this)
		return this
	}

	; static MakeClickThrough(guiObj := this) {
	; 	if (guiObj is Gui){
	; 		; WinSetTransparent(255, guiObj)
	; 		WinSetTransparent(255, this)
	; 		guiObj.Opt('+E0x20')
	; 	}
	; 	return this
	; }

	/**
	 * @description Enables double-buffered composited window rendering
	 * @returns {Gui} The Gui object for method chaining
	 * @example
	 * gui.EnableComposited()
	 */
	static EnableComposited() {
		WinSetExStyle('+' this.WS_EX_COMPOSITED, this)
		return this
	}

	/**
	 * @description Adds 3D sunken edge border to window
	 * @returns {Gui} The Gui object for method chaining
	 * @example
	 * gui.AddClientEdge()
	 */
	static AddClientEdge() {
		WinSetExStyle('+' this.WS_EX_CLIENTEDGE, this)
		return this
	}

	/**
	 * @description Forces window to have a taskbar button
	 * @returns {Gui} The Gui object for method chaining
	 * @example
	 * gui.ForceTaskbarButton()
	 */
	static ForceTaskbarButton() {
		WinSetExStyle('+' this.WS_EX_APPWINDOW, this)
		return this
	}

	/**
	 * @description Makes window layered for transparency effects
	 * @returns {Gui} The Gui object for method chaining
	 * @example
	 * gui.MakeLayered()
	 */
	static MakeLayered() {
		WinSetExStyle('+' this.WS_EX_LAYERED, this)
		return this
	}

	/**
	 * @description Creates a tool window with no taskbar button
	 * @returns {Gui} The Gui object for method chaining
	 * @example
	 * gui.MakeToolWindow()
	 */
	static MakeToolWindow() {
		WinSetExStyle('+' this.WS_EX_TOOLWINDOW, this)
		return this
	}

	/**
	 * @description Sets window to always stay on top
	 * @returns {Gui} The Gui object for method chaining
	 * @example
	 * gui.SetAlwaysOnTop()
	 */
	static SetAlwaysOnTop() {
		WinSetExStyle('+' this.WS_EX_TOPMOST, this)
		return this
	}

	/**
	 * @description Enables drag and drop file acceptance
	 * @returns {Gui} The Gui object for method chaining
	 * @example
	 * gui.EnableDragDrop()
	 */
	static EnableDragDrop() {
		WinSetExStyle('+' this.WS_EX_ACCEPTFILES, this)
		return this
	}

	/**
	 * @description Adds help button (?) to titlebar
	 * @returns {Gui} The Gui object for method chaining
	 * @example
	 * gui.AddHelpButton()
	 */
	static AddHelpButton() {
		WinSetExStyle('+' this.WS_EX_CONTEXTHELP, this)
		return this
	}

	/**
	 * @description Sets window transparency level
	 * @param {Integer} level Transparency level (0-255, where 0 is invisible and 255 is opaque)
	 * @returns {Gui} The Gui object for method chaining
	 * @example
	 * gui.SetTransparency(180)  ; Set to 70% opacity
	 */
	static SetTransparency(level := 255) {
		if (level < 0 || level > 255)
			throw ValueError("Transparency level must be between 0 and 255")
		
		this.MakeLayered()  ; Window must be layered for transparency
		WinSetTransparent(level, this)
		return this
	}

	; static SetButtonWidth(input, bMargin := 1.5) {
	; 	return GuiButtonProperties.SetButtonWidth(input, bMargin)
	; }

	/**
	 * @description Creates an overlay window combining multiple styles
	 * @param {Object} options Window style options
	 * @returns {Gui} The Gui object for method chaining
	 * @example
	 * gui.CreateOverlay({
	*    transparency: 200,
	*    clickThrough: true,
	*    alwaysOnTop: true
	* })
	*/
	static CreateOverlay(options := {}) {

		this.NoActivate()

		if (options.HasProp("transparency")){
			this.SetTransparency(options.transparency)
		}
		if (options.Get("clickThrough", false)){
			this.MakeClickThrough()
		}
		if (options.Get("alwaysOnTop", true)){
			this.SetAlwaysOnTop()
		}
		if (options.Get("composited", true)){
			this.EnableComposited()
		}

		return this
	}

	/**
	 * @description Creates a floating toolbar window
	 * @param {Object} options Window style options
	 * @returns {Gui} The Gui object for method chaining
	 * @example
	 * gui.CreateToolbar({
	*    alwaysOnTop: true,
	*    dropShadow: true
	* })
	*/
	static CreateToolbar(options := {}) {
		
		this.MakeToolWindow()
		
		if (options.Get("alwaysOnTop", true)){
			this.SetAlwaysOnTop()
		}
		if (options.Get("acceptFiles", false)){
			this.EnableDragDrop()
		}
		if (options.Get("dropShadow", true)){
			this.AddClientEdge()
		}

		return this
	}

	static SetButtonWidth(params*) {
		input := bMargin := ''
		
		; Parse parameters
		for i, param in params {
			if (i = 1) {
				input := param
			}
			else if (i = 2) {
				bMargin := param
			}
		}
		
		; Set default margin if not provided
		bMargin := bMargin ? bMargin : 1.5
		
		return GuiButtonProperties.SetButtonWidth(input, bMargin)
	}

	; static SetButtonHeight(rows := 1, vMargin := 1.2) {
	; 	return GuiButtonProperties.SetButtonHeight(rows, vMargin)
	; }

	static SetButtonHeight(params*) {
		rows := vMargin := ''
		
		; Parse parameters
		for i, param in params {
			if (i = 1)
				rows := param
			else if (i = 2)
				vMargin := param
		}
		
		; Set defaults if not provided
		rows := rows ? rows : 1
		vMargin := vMargin ? vMargin : 1.2
		
		return GuiButtonProperties.SetButtonHeight(rows, vMargin)
	}

	static GetButtonDimensions(text, options := {}) {
		return GuiButtonProperties.GetButtonDimensions(text, options)
	}

	static GetOptimalButtonLayout(totalButtons, containerWidth, containerHeight) {
		return GuiButtonProperties.GetOptimalButtonLayout(totalButtons, containerWidth, containerHeight)
	}

	static _AddButtonGroup(guiObj, buttonOptions, labelObj, groupOptions := '', columns := 1) {
		buttons := Map()
		
		if (Type(labelObj) = 'String') {
			labelObj := StrSplit(labelObj, '|')
		}
		
		if (Type(labelObj) = 'Array' or Type(labelObj) = 'Map' or Type(labelObj) = 'Object') {
			totalButtons := labelObj.Length
			rows := Ceil(totalButtons / columns)
			
			; Parse groupOptions
			groupPos := '', groupSize := ''
			if (groupOptions != '') {
				RegExMatch(groupOptions, 'i)x\s*(\d+)', &xMatch)
				RegExMatch(groupOptions, 'i)y\s*(\d+)', &yMatch)
				RegExMatch(groupOptions, 'i)w\s*(\d+)', &wMatch)
				RegExMatch(groupOptions, 'i)h\s*(\d+)', &hMatch)
				
				groupPos := (xMatch ? 'x' . xMatch[1] : '') . ' ' . (yMatch ? 'y' . yMatch[1] : '')
				groupSize := (wMatch ? 'w' . wMatch[1] : '') . ' ' . (hMatch ? 'h' . hMatch[1] : '')
			}
			
			groupBox := guiObj.AddGroupBox(groupPos . ' ' . groupSize, 'Button Group')
			groupBox.GetPos(&groupX, &groupY, &groupW, &groupH)
			
			btnWidth := this.SetButtonWidth(labelObj)
			btnHeight := this.SetButtonHeight()
			
			xMargin := 10
			yMargin := 25
			xSpacing := 10
			ySpacing := 5
			
			for index, label in labelObj {
				col := Mod(A_Index - 1, columns)
				row := Floor((A_Index - 1) / columns)
				
				xPos := groupX + xMargin + (col * (btnWidth + xSpacing))
				yPos := groupY + yMargin + (row * (btnHeight + ySpacing))
				
				btnOptions := StrReplace(buttonOptions, 'xm', 'x' . xPos)
				btnOptions := StrReplace(btnOptions, 'ym', 'y' . yPos)
				btnOptions := 'x' . xPos . ' y' . yPos . ' w' . btnWidth . ' h' . btnHeight . ' ' . btnOptions
				
				btn := guiObj.AddButton(btnOptions, label)
				buttons[label] := btn
			}
			
			; Only resize the group box if buttons were actually added
			if (buttons.Count > 0) {
				lastButton := buttons[labelObj[labelObj.Length]]
				lastButton.GetPos(&lastX, &lastY, &lastW, &lastH)
				newGroupW := lastX + lastW + xMargin - groupX
				newGroupH := lastY + lastH + yMargin - groupY
				groupBox.Move(,, newGroupW, newGroupH)
			}
		}
		
		return buttons
	}

	static AddButtonGroup(params*) {
		; Initialize default values
		config := {
			guiObj: '',
			buttonOptions: '',
			labelObj: '',
			groupOptions: '',
			columns: 1
		}
		
		; Parse parameters
		for i, param in params {
			if (param is Gui)
				config.guiObj := param
			else if (i = 2)
				config.buttonOptions := param
			else if (Type(param) = "String" && InStr(param, "x") || InStr(param, "y"))
				config.groupOptions := param
			else if (Type(param) = "Array" || Type(param) = "String")
				config.labelObj := param
			else if (Type(param) = "Integer")
				config.columns := param
		}
		
		; Call original implementation with parsed parameters
		return this._AddButtonGroup(config.guiObj, config.buttonOptions, config.labelObj, config.groupOptions, config.columns)
	}

	static OriginalPositions := Map()

	static AddCustomizationOptions(GuiObj) {
		; Get position for the new group box
		GuiObj.groupBox.GetPos(&gX, &gY, &gW, &gH)
		
		; Add a new group box for customization options
		GuiObj.AddGroupBox("x" gX " y" (gY + gH + 10) " w" gW " h100", "GUI Customization")
		
		; Add checkboxes for enabling customization and saving settings
		GuiObj.AddCheckbox("x" (gX + 10) " y+10 vEnableCustomization", "Enable Customization")
			.OnEvent("Click", (*) => this.ToggleCustomization(GuiObj))
		GuiObj.AddCheckbox("x+10 vSaveSettings", "Save Settings")
			.OnEvent("Click", (*) => this.ToggleSaveSettings(GuiObj))
		
		; Add button for adjusting positions
		GuiObj.AddButton("x" (gX + 10) " y+10 w100 vAdjustPositions", "Adjust Positions")
			.OnEvent("Click", (*) => this.ShowAdjustPositionsGUI(GuiObj))
		
		; Add text size control
		GuiObj.AddText("x+10 y+-15", "Text Size:")
		GuiObj.AddEdit("x+5 w30 vTextSize", "14")
			.OnEvent("Change", (*) => this.UpdateTextSize(GuiObj))

		; Add custom hotkey option
		GuiObj.AddText("x" (gX + 10) " y+10", "Custom Hotkey:")
		GuiObj.AddHotkey("x+5 w100 vCustomHotkey")
			.OnEvent("Change", (*) => this.UpdateCustomHotkey(GuiObj))

		; Store original positions
		this.StoreOriginalPositions(GuiObj)

		; Add methods to GuiObj
		GuiObj.DefineProp("ApplySettings", {Call: (self, settings) => this.ApplySettings(self, settings)})
		GuiObj.DefineProp("SaveSettings", {Call: (self) => this.SaveSettings(self)})
		GuiObj.DefineProp("LoadSettings", {Call: (self) => this.LoadSettings(self)})
	}

	static StoreOriginalPositions(GuiObj) {
		this.OriginalPositions[GuiObj.Hwnd] := Map()
		for ctrl in GuiObj {
			ctrl.GetPos(&x, &y)
			this.OriginalPositions[GuiObj.Hwnd][ctrl.Name] := {x: x, y: y}
		}
	}

	static ToggleCustomization(GuiObj) {
		isEnabled := GuiObj["EnableCustomization"].Value
		GuiObj["AdjustPositions"].Enabled := isEnabled
		GuiObj["TextSize"].Enabled := isEnabled
		GuiObj["CustomHotkey"].Enabled := isEnabled
	}

	static ToggleSaveSettings(GuiObj) {
		if (GuiObj["SaveSettings"].Value) {
			this.SaveSettings(GuiObj)
		}
	}

	static UpdateTextSize(GuiObj) {
		newSize := GuiObj["TextSize"].Value
		if (newSize is integer && newSize > 0) {
			GuiObj.SetFont("s" newSize)
			for ctrl in GuiObj {
				if (ctrl.Type == "Text" || ctrl.Type == "Edit" || ctrl.Type == "Button") {
					ctrl.SetFont("s" newSize)
				}
			}
		}
	}

	static UpdateCustomHotkey(GuiObj) {
		newHotkey := GuiObj["CustomHotkey"].Value
		if (newHotkey) {
			Hotkey(newHotkey, (*) => this.ToggleVisibility(GuiObj))
		}
	}

	static ToggleVisibility(GuiObj) {
		if (GuiObj.Visible) {
			GuiObj.Hide()
		} else {
			GuiObj.Show()
		}
	}

	static ShowAdjustPositionsGUI(GuiObj) {
		adjustGui := Gui("+AlwaysOnTop", "Adjust Control Positions")
		
		for ctrl in GuiObj {
			if (ctrl.Type != "GroupBox") {
				adjustGui.AddText("w150", ctrl.Name)
				adjustGui.AddButton("x+5 w20 h20", "↑").OnEvent("Click", (*) => this.MoveControl(GuiObj, ctrl, 0, -5))
				adjustGui.AddButton("x+5 w20 h20", "↓").OnEvent("Click", (*) => this.MoveControl(GuiObj, ctrl, 0, 5))
				adjustGui.AddButton("x+5 w20 h20", "←").OnEvent("Click", (*) => this.MoveControl(GuiObj, ctrl, -5, 0))
				adjustGui.AddButton("x+5 w20 h20", "→").OnEvent("Click", (*) => this.MoveControl(GuiObj, ctrl, 5, 0))
				adjustGui.AddButton("x+10 w60", "Reset").OnEvent("Click", (*) => this.ResetControlPosition(GuiObj, ctrl))
			}
		}
		
		adjustGui.AddButton("x10 w100", "Save").OnEvent("Click", (*) => (this.SaveSettings(GuiObj), adjustGui.Destroy()))
		adjustGui.Show()
	}

	static MoveControl(GuiObj, ctrl, dx, dy) {
		ctrl.GetPos(&x, &y)
		ctrl.Move(x + dx, y + dy)
	}

	static ResetControlPosition(GuiObj, ctrl) {
		if (this.OriginalPositions.Has(GuiObj.Hwnd) && this.OriginalPositions[GuiObj.Hwnd].Has(ctrl.Name)) {
			originalPos := this.OriginalPositions[GuiObj.Hwnd][ctrl.Name]
			ctrl.Move(originalPos.x, originalPos.y)
		}
	}

	static SaveSettings(GuiObj) {
		settings := Map(
			"GuiSize", {w: GuiObj.Pos.W, h: GuiObj.Pos.H},
			"ControlPositions", this.GetControlPositions(GuiObj),
			"TextSize", GuiObj["TextSize"].Value,
			"CustomHotkey", GuiObj["CustomHotkey"].Value
		)
		FileDelete(A_ScriptDir "\GUISettings.json")
		FileAppend(cJSON.Stringify(settings), A_ScriptDir "\GUISettings.json")
	}

	static LoadSettings(GuiObj) {
		if (FileExist(A_ScriptDir "\GUISettings.json")) {
			settings := cJSON.Load(FileRead(A_ScriptDir "\GUISettings.json"))
			this.ApplySettings(GuiObj, settings)
		}
	}

	static ApplySettings(GuiObj, settings) {
		if (settings.Has("GuiSize")) {
			GuiObj.Move(,, settings.GuiSize.w, settings.GuiSize.h)
		}
		if (settings.Has("ControlPositions")) {
			this.SetControlPositions(GuiObj, settings.ControlPositions)
		}
		if (settings.Has("TextSize")) {
			GuiObj["TextSize"].Value := settings.TextSize
			this.UpdateTextSize(GuiObj)
		}
		if (settings.Has("CustomHotkey")) {
			GuiObj["CustomHotkey"].Value := settings.CustomHotkey
			this.UpdateCustomHotkey(GuiObj)
		}
	}

	static GetControlPositions(GuiObj) {
		positions := Map()
		for ctrl in GuiObj {
			ctrl.GetPos(&x, &y)
			positions[ctrl.Name] := {x: x, y: y}
		}
		return positions
	}

	static SetControlPositions(GuiObj, positions) {
		for ctrlName, pos in positions {
			if (GuiObj.HasProp(ctrlName)) {
				GuiObj[ctrlName].Move(pos.x, pos.y)
			}
		}
	}

	; Static wrapper methods
	static AddCustomizationOptionsToGui(GuiObj?) {
		if !GuiObj {
			guiObj := this
		}
		GuiObj.AddCustomizationOptions()
		return this
	}

	static SaveGuiSettings(GuiObj?) {
		GuiObj.SaveSettings()
		return this
	}

	static LoadGuiSettings(GuiObj?) {
		GuiObj.LoadSettings()
		return this
	}

	class Color {
		
		; Use existing color map
		static mColors := GuiColors.mColors

		/**
		 * Converts color from various formats to RGB
		 * @param {*} params color [, options]
		 * @returns {Object} {r, g, b} color components
		 */
		static ToRGB(params*) {
			color := params[1]
			
			if color is Integer
				return {r: (color >> 16) & 0xFF, 
					g: (color >> 8) & 0xFF, 
					b: color & 0xFF}
				
			if IsObject(color)
				return color

			if this.mColors.Has(StrLower(color))
				color := this.mColors[StrLower(color)]
				
			if RegExMatch(color, "i)^#?([A-F0-9]{6})$", &match)
				color := match[1]
				
			return {r: Integer("0x" SubStr(color, 1, 2)),
					g: Integer("0x" SubStr(color, 3, 2)),
					b: Integer("0x" SubStr(color, 5, 2))}
		}

		/**
		 * Converts color to BGR format
		 * @param {*} params color [, options]
		 * @returns {Integer} BGR color value
		 */
		static ToBGR(params*) {
			rgb := this.ToRGB(params[1])
			return (rgb.b << 16) | (rgb.g << 8) | rgb.r
		}

		/**
		 * Converts color to hex string
		 * @param {*} params color [, options]
		 * @returns {String} Hex color string
		 */
		static ToHex(params*) {
			rgb := this.ToRGB(params[1])
			return Format("{:02X}{:02X}{:02X}", rgb.r, rgb.g, rgb.b)
		}

		/**
		 * Adjusts color brightness
		 * @param {*} params color, amount [, options]
		 * @returns {String} Hex color
		 */
		static Adjust(params*) {
			if params.Length < 2
				throw ValueError("Requires color and amount parameters")
				
			color := params[1]
			amount := params[2]
			rgb := this.ToRGB(color)
			amount := Min(1.0, Max(-1.0, amount))
			
			rgb.r := Min(255, Max(0, Round(rgb.r * (1 + amount))))
			rgb.g := Min(255, Max(0, Round(rgb.g * (1 + amount))))
			rgb.b := Min(255, Max(0, Round(rgb.b * (1 + amount))))
			
			return this.ToHex(rgb)
		}

		/**
		 * Mixes two colors
		 * @param {*} params color1, color2 [, ratio=0.5] [, options]
		 * @returns {String} Hex color
		 */
		static Mix(params*) {
			if params.Length < 2
				throw ValueError("Requires at least two colors")
				
			color1 := params[1]
			color2 := params[2]
			ratio := params.Length > 2 ? params[3] : 0.5
			
			c1 := this.ToRGB(color1)
			c2 := this.ToRGB(color2)
			ratio := Min(1, Max(0, ratio))
			
			return this.ToHex({
				r: Round(c1.r * (1 - ratio) + c2.r * ratio),
				g: Round(c1.g * (1 - ratio) + c2.g * ratio),
				b: Round(c1.b * (1 - ratio) + c2.b * ratio)
			})
		}
	}
	
		/**
	 * Add a RichEdit control to a GUI
	 * @param {Gui} guiObj The GUI object to add the control to
	 * @param {String} options Control options string
	 * @param {String} text Initial text content
	 * @returns {RichEdit} The created RichEdit control
	 */

	; static AddRichEdit(guiObj?, options := "", text := "") {
	; 	if !IsSet(guiObj) {
	; 		guiObj := this
	; 	}
	; 	; Default options if none provided
	; 	if (options = "") {
	; 		options := "w400 h300"  ; Default size
	; 	}

	; 	; Create RichEdit control
	; 	reObj := RichEdit(guiObj, options)
		
	; 	; Set initial text if provided
	; 	if (text != "") {
	; 		reObj.SetText(text)
	; 	}
		
	; 	; Configure default settings
	; 	reObj.SetOptions(["SELECTIONBAR"])  ; Enable selection bar
	; 	reObj.AutoURL(true)                 ; Enable URL detection
	; 	reObj.SetEventMask([
	; 		"SELCHANGE",                    ; Selection change events
	; 		"LINK",                         ; Link click events
	; 		"PROTECTED"                     ; Protected text events
	; 	])
		
	; 	return reObj
	; }

	/**
	 * 
	 * @param guiObj 
	 * @param options 
	 * @param text 
	 */
	static AddRichEdit(options := '', text := "", toolbar := true, showScrollBars := false) {
		; 'this' refers to the Gui instance here
		guiObj := this
		; Create RichEdit control with default size if none specified
		if !IsSet(options) {
			options := "w400 r10"  ; Default size
		}
		
		; Create RichEdit control
		reObj := RichEdit(this, options)
		; Calculate positions
		; Set sizing properties
		reObj.WidthP := 1.0   ; Take full width
		reObj.HeightP := 1.0  ; Take full height after toolbar
		reObj.MinWidth := 200
		reObj.MinHeight := 100
		reObj.AnchorIn := true

		; Initialize GuiReSizer for the parent GUI
		guiObj.Init := 2  ; Force initial resize

		; Ensure parent GUI resizes properly
		guiObj.OnEvent("Size", GuiReSizer)
		btnW := 18, btnH := 15, margin := 1
		
		; If toolbar enabled, add it before the RichEdit
		if (toolbar) {
			toolbarH := btnH + margin*2
			x := margin
			y := margin

			; Bold
			boldBtn := guiObj.AddButton(Format("x{1} y{2} w{3} h{4}", x, y, btnW, btnH), "B")
			x += btnW + margin
			
			; Italic
			italicBtn := guiObj.AddButton(Format("x{1} y{2} w{3} h{4}", x, y, btnW, btnH), "I")
			x += btnW + margin

			; Underline 
			underBtn := guiObj.AddButton(Format("x{1} y{2} w{3} h{4}", x, y, btnW, btnH), "U")
			x += btnW + margin

			; Strikethrough
			strikeBtn := guiObj.AddButton(Format("x{1} y{2} w{3} h{4}", x, y, btnW, btnH), "S")

			; Position RichEdit below toolbar
			options := "x" margin " y" (y + btnH + margin) " " options
		}

		; ; Create RichEdit control with default size if none specified
		; if !IsSet(options) {
		;     options := "w400 r10"  ; Default size
		; }
		
		; ; Create RichEdit control
		; reObj := RichEdit(this, options)
		reObj.SetFont({Name: "Times New Roman", Size: 9})
		; Add GuiReSizer properties after creating RichEdit
		reObj.GetPos(&xPos, &yPos, &wGui, &hGui)

		; Add resizing properties for GUI
		if (toolbar) {
			; Account for toolbar space if present
			reObj.X := margin
			reObj.Y := btnH + margin*2
		} else {
			reObj.X := margin
			reObj.Y := margin
		}
		
		; Configure scrollbar visibility
		if (!showScrollBars) {
			reObj.SetOptions([
				"SELECTIONBAR",
				; "MULTILEVEL",
				"AUTOWORDSEL",
				; "-HSCROLL",  ; Disable horizontal scrollbar
				; "-VSCROLL"   ; Disable vertical scrollbar
				; "-AUTOVSCROLL",  ; Show vertical scrollbar when needed
				; "-AUTOHSCROLL"   ; Show horizontal scrollbar when needed
			])
		} else {
			reObj.SetOptions([
				"SELECTIONBAR",
				"MULTILEVEL",
				"AUTOWORDSEL",
				"AUTOVSCROLL",  ; Show vertical scrollbar when needed
				"AUTOHSCROLL"   ; Show horizontal scrollbar when needed
			])
		}
		
		; Enable features
		reObj.AutoURL(true)                 ; Enable URL detection
		reObj.SetEventMask([
			"SELCHANGE",                    ; Selection change events
			"LINK",                         ; Link click events
			"PROTECTED",                    ; Protected text events
			"CHANGE"                        ; Text change events
		])
	
		; Add GuiReSizer properties for automatic sizing
		reObj.WidthP := 1.0      ; Take up full width
		reObj.HeightP := 1.0     ; Take up full height
		reObj.MinWidth := 200    ; Minimum dimensions
		reObj.MinHeight := 100
		reObj.AnchorIn := true   ; Stay within parent bounds
	
		; Add basic keyboard shortcuts
		HotIfWinactive("ahk_id " reObj.Hwnd)
		Hotkey("^b", (*) => reObj.ToggleFontStyle("B"))
		Hotkey("^i", (*) => reObj.ToggleFontStyle("I"))
		Hotkey("^u", (*) => reObj.ToggleFontStyle("U"))
		Hotkey("^+s", (*) => reObj.ToggleFontStyle("S"))
		Hotkey("^z", (*) => reObj.Undo())
		Hotkey("^y", (*) => reObj.Redo())
		HotIf()
	
		; Set initial text if provided
		if IsSet(text) {
			reObj.SetText(text)
		}
		
		; Define button callbacks
		BoldText(*) {
			reObj.ToggleFontStyle("B")
			reObj.Focus()
		}
		
		ItalicText(*) {
			reObj.ToggleFontStyle("I")
			reObj.Focus()
		}
		
		UnderlineText(*) {
			reObj.ToggleFontStyle("U")
			reObj.Focus()
		}
		
		StrikeText(*) {
			reObj.ToggleFontStyle("S")
			reObj.Focus()
		}

		return reObj
	}
	
	/**
	 * Extension method for Gui class
	 * @param {String} options Control options
	 * @param {String} text Initial text
	 * @returns {RichEdit} The created RichEdit control
	 */
	static AddRTE(options := "", text := "") {
		return this.AddRichEdit(this, options, text)
	}

	; static AddRichTextEdit(options := "", text := ""){
	; 	return this.AddRichEdit(this, options, text)
	; }
	/**
	 * Extension method for Gui class
	 * @param {String} options Control options
	 * @param {String} text Initial text
	 * @returns {RichEdit} The created RichEdit control
	 */
	static AddRichTextEdit(options := "", text := "") => this.AddRichEdit(this, options, text)
	/**
	 * Extension method for Gui class
	 * @param {String} options Control options
	 * @param {String} text Initial text
	 * @returns {RichEdit} The created RichEdit control
	 */
	static AddRichText(options := "", text := "") => this.AddRichEdit(this, options, text)

	static SetDefaultFont(guiObj := this, fontObj := '') {
		if (guiObj is Gui) {

			if (IsObject(fontObj)) {
				; Use the provided font object
				size := fontObj.HasProp('Size') ? 's' . fontObj.Size : 's9'
				weight := fontObj.HasProp('Weight') ? ' w' . fontObj.Weight : ''
				italic := fontObj.HasProp('Italic') && fontObj.Italic ? ' Italic' : ''
				underline := fontObj.HasProp('Underline') && fontObj.Underline ? ' Underline' : ''
				strikeout := fontObj.HasProp('Strikeout') && fontObj.Strikeout ? ' Strike' : ''
				name := fontObj.HasProp('Name') ? fontObj.Name : 'Segoe UI'

				options := size . weight . italic . underline . strikeout
				guiObj.SetFont(options, name)
			} else if !guiObj.HasProp('Font') {
				; Use default settings if no font object is provided
				guiObj.SetFont('s9', 'Segoe UI')
			}
		}
		return this
	}
}
; ---------------------------------------------------------------------------
;; @endregion

;; @class CheckBoxManager
class CheckBoxManager {
	/************************************************************************
	* @description Stores found checkboxes and their states
	***********************************************************************/
	checkboxes := []
	currentIndex := 0

	/************************************************************************
	* @description Find and cache all checkboxes on the page
	* @example checkboxManager.FindAllCheckboxes()
	***********************************************************************/
	FindAllCheckboxes() {
		this.checkboxes := []
		try {
			expRpt := UIA.ElementFromChromium(' - Google Chrome')
			if !expRpt
				throw Error("Chrome window not found")
			
			; Find all checkboxes
			; foundBoxes := expRpt.FindAll({Type: '50002', LocalizedType: "check box"})
			foundBoxes := expRpt.FindAll({LocalizedType: "check box"})
			for box in foundBoxes{
				this.checkboxes.Push(box)
			}
			return this.checkboxes.Length
		} catch Error as e {
			throw Error("Failed to find checkboxes: " e.Message)
		}
	}

	/************************************************************************
	* @description Process the next unchecked checkbox in the list
	* @example checkboxManager.ProcessNextCheckbox()
	***********************************************************************/
	ProcessNextCheckbox() {
		if (this.checkboxes.Length = 0)
			this.FindAllCheckboxes()
		
		if (this.checkboxes.Length = 0)
			throw Error("No checkboxes found")
		
		loop this.checkboxes.Length {
			this.currentIndex++
			if (this.currentIndex > this.checkboxes.Length)
				this.currentIndex := 1
			
			currentBox := this.checkboxes[this.currentIndex]
			if (!this.IsCheckboxChecked(currentBox)) {
				this.FocusAndCheck(currentBox)
				return true
			}
		}
		
		return false ; No unchecked boxes found
	}

	/************************************************************************
	* @description Check if a checkbox is currently checked
	* @example if !checkboxManager.IsCheckboxChecked(checkbox)
	***********************************************************************/
	IsCheckboxChecked(checkbox) {
		try {
			return checkbox.GetPropertyValue(UIA.Property.ToggleToggleState)
		} catch {
			return false
		}
	}

	/************************************************************************
	* @description Focus on a checkbox and check it
	* @example checkboxManager.FocusAndCheck(checkbox)
	***********************************************************************/
	FocusAndCheck(checkbox) {
		try {
			checkbox.ScrollIntoView()
			Sleep(100)  ; Give UI time to update
			checkbox.SetFocus()
			Sleep(100)
			
			if (!this.IsCheckboxChecked(checkbox))
				checkbox.Click()
			
			return true
		} catch Error as e {
			throw Error("Failed to check checkbox: " e.Message)
		}
	}
}
; ---------------------------------------------------------------------------
;; @endregion
;; @class DisplaySettings
/**
 * @class DisplaySettings
 * @description Manages display settings for various GUI elements
 */
class DisplaySettings {
	; Store all settings maps
	static Settings := Map(
		"Base", {
			; Common base settings for all displays
			Font: {
				Name: "Consolas",
				Size: 10,
				Quality: 5,
				Color: "cBlue"
			},
			Colors: {
				Background: "cBlack",
				Text: "000000"
			},
			Styles: "+AlwaysOnTop -Caption +ToolWindow",
			Margins: {
				X: 0,
				Y: 0
			},
			Grid: {
				Enabled: true,
				Columns: 3,
				Rows: 10,
				Spacing: 10
			}
		},
		"Infos", {
			; Infos-specific settings
			Font: {
				Size: 8,
				Quality: 5
			},
			Metrics: {
				Distance: 4,
				Unit: A_ScreenDPI / 144
			},
			Position: {
				Mode: "Grid",  ; "Grid", "Fixed", "Center"
				Column: 1,     ; Single column for traditional Infos
				MaxRows: Floor(A_ScreenHeight / (8 * (A_ScreenDPI / 144) * 4))
			},
			Limits: {
				MaxNumberedHotkeys: 12,
				MaxWidthInChars: 110
			}
		},
		"CleanInputBox", {
			; CleanInputBox-specific settings
			Size: {
				Width: Round(A_ScreenWidth / 3),
				MinHeight: 30
			},
			Position: {
				Mode: "Center",
				TopMargin: Round(A_ScreenHeight / 1080 * 800)
			},
			Font: {
				Size: 12
			},
			Input: {
				MinChars: 2,
				MaxMatches: 5,
				ShowMatchList: true
			}
		},
		"InputBox", {
			; Future InputBox-specific settings
			Size: {
				Width: Round(A_ScreenWidth / 4),
				Height: "Auto"
			},
			Position: {
				Mode: "Fixed",
				X: 100,
				Y: 100
			},
			Font: {
				Size: 11
			}
		}
	)

	/**
	 * Get settings for a specific display type
	 * @param {String} type The display type ("Infos", "CleanInputBox", etc)
	 * @returns {Object} Merged settings
	 */
	static GetSettings(type) {
		; Start with base settings
		mergedSettings := this.CloneMap(this.Settings["Base"])
		
		; Merge with type-specific settings if they exist
		if (this.Settings.Has(type)) {
			mergedSettings := this.MergeSettings(mergedSettings, this.Settings[type])
		}

		return mergedSettings
	}

	/**
	 * Update settings for a display type
	 * @param {String} type The display type
	 * @param {Object} newSettings New settings to apply
	 */
	static UpdateSettings(type, newSettings) {
		if (this.Settings.Has(type)) {
			this.Settings[type] := this.MergeSettings(this.Settings[type], newSettings)
		} else {
			this.Settings[type] := newSettings
		}
	}

	/**
	 * Deep clone a Map or Object
	 * @param {Map|Object} source Source to clone
	 * @returns {Map|Object} Cloned copy
	 */
	static CloneMap(source) {
		if (Type(source) = "Map") {
			result := Map()
			for key, value in source {
				result[key] := IsObject(value) ? this.CloneMap(value) : value
			}
			return result
		} else if (IsObject(source)) {
			result := {}
			for key, value in source.OwnProps() {
				result.%key% := IsObject(value) ? this.CloneMap(value) : value
			}
			return result
		}
		return source
	}

	/**
	 * Deep merge settings objects
	 * @param {Object} target Target object
	 * @param {Object} source Source object
	 * @returns {Object} Merged result
	 */
	static MergeSettings(target, source) {
		result := this.CloneMap(target)
		
		if (Type(source) = "Map") {
			for key, value in source {
				if (Type(value) = "Map" || IsObject(value)) {
					if (result.Has(key)) {
						result[key] := this.MergeSettings(result[key], value)
					} else {
						result[key] := this.CloneMap(value)
					}
				} else {
					result[key] := value
				}
			}
		} else if (IsObject(source)) {
			for key, value in source.OwnProps() {
				if (IsObject(value)) {
					if (result.HasProp(key)) {
						result.%key% := this.MergeSettings(result.%key%, value)
					} else {
						result.%key% := this.CloneMap(value)
					}
				} else {
					result.%key% := value
				}
			}
		}
		
		return result
	}

	/**
	 * Calculate derived settings (those that depend on other settings)
	 * @param {String} type Display type
	 * @param {Object} settings Base settings object
	 * @returns {Object} Settings with calculated values
	 */
	static CalculateDerivedSettings(type, settings) {
		derived := this.CloneMap(settings)
		
		switch type {
			case "Infos":
				; Calculate GUI width based on font metrics
				derived.guiWidth := derived.Font.Size 
					* derived.Metrics.Unit 
					* derived.Metrics.Distance
				
				; Calculate maximum instances based on screen height
				derived.maxInstances := Floor(A_ScreenHeight / derived.guiWidth)
				
			case "CleanInputBox":
				; Calculate centered position
				derived.Position.X := (A_ScreenWidth - derived.Size.Width) / 2
				derived.Position.Y := derived.Position.TopMargin
		}
		
		return derived
	}
}
; ---------------------------------------------------------------------------
/**
 * @class InfoBox
 * @description Base class for creating positioned info boxes with grid support
 */

/**
 * @class InfoBox
 * @description Core GUI creation and management functionality
 */
class InfoBox {
	static Instances := Map()
	static Grid := Map()

	__New(settings) {
		this.settings := settings
		; this.InitializeGrid()
		this.position := this.GetPosition()
		
		if (!this.position) {
			return
		}

		this.gui := Gui(this.settings.Styles)
		this.SetupGui()
		InfoBox.Instances[this.gui.Hwnd] := this
	}

	InitializeGrid() {
		if (this.settings.Position.Mode = "Grid") {
			gridId := this.settings.Grid.ID

			; Initialize grid if not exists
			if (!InfoBox.Grid.Has(gridId)) {
				InfoBox.Grid[gridId] := Array(this.settings.Grid.Rows)
				loop this.settings.Grid.Rows {
					row := A_Index
					InfoBox.Grid[gridId][row] := Array(this.settings.Grid.Columns)
					loop this.settings.Grid.Columns {
						InfoBox.Grid[gridId][row][A_Index] := false
					}
				}
			}
		}
	}

	SetupGui() {
		; Apply base settings
		this.gui.MarginX := this.settings.Margins.X
		this.gui.MarginY := this.settings.Margins.Y
		this.gui.BackColor := this.settings.Colors.Background

		; Set font
		this.gui.SetFont(
			"s" this.settings.Font.Size " q" this.settings.Font.Quality 
			" " this.settings.Font.Color,
			this.settings.Font.Name
		)
	}

	AddControl(type, options, text := "") {
		control := this.gui.Add(type, options, text)
		return control
	}

	GetPosition() {
		; if (this.settings.Position.Mode = "Grid") {
		; 	return this.GetGridPosition()
		; } else if (this.settings.Position.Mode = "Center") {
		; 	return this.GetCenteredPosition()
		; }
		; return {
		; 	x: this.settings.Position.X,
		; 	y: this.settings.Position.Y,
		; 	row: 0,
		; 	col: 0
		; }
		return this.GetCenteredPosition()
	}

	GetGridPosition() {
		gridId := this.settings.Grid.ID
		grid := InfoBox.Grid[gridId]
		
		loop this.settings.Grid.Rows {
			row := A_Index
			loop this.settings.Grid.Columns {
				col := A_Index
				if (!grid[row][col]) {
					grid[row][col] := true
					return {
						x: (col - 1) * (this.settings.Size.Width + this.settings.Grid.Spacing),
						y: (row - 1) * (this.settings.Size.Height + this.settings.Grid.Spacing),
						row: row,
						col: col
					}
				}
			}
		}
		return false
	}

	GetCenteredPosition() {
		return {
			x: (A_ScreenWidth - this.settings.Size.Width) / 2,
			y: this.settings.Position.HasProp("TopMargin") ? this.settings.Position.TopMargin : (A_ScreenHeight / 3),
			row: 0,
			col: 0
		}
	}

	Show(options := "") {
		if (this.position) {
			showOptions := options ? options 
				: Format("x{1} y{2} AutoSize", this.position.x, this.position.y)
			this.gui.Show(showOptions)
		}
	}

	Hide() {
		this.gui.Hide()
	}

	Destroy() {
		; Release grid position if using grid
		if (this.position && this.settings.Position.Mode = "Grid") {
			gridId := this.settings.Grid.ID
			InfoBox.Grid[gridId][this.position.row][this.position.col] := false
		}

		; Remove from instances
		InfoBox.Instances.Delete(this.gui.Hwnd)
		
		; Destroy GUI
		this.gui.Destroy()
	}

	static DestroyAll() {
		for hwnd, instance in InfoBox.Instances.Clone() {
			instance.Destroy()
		}
	}
}
; ---------------------------------------------------------------------------

/**
 * @class Infos
 * @description Information display box with grid-based positioning
 */
; class Infos {
; 	static __New() {
; 		; Calculate basic metrics
; 		unit := A_ScreenDPI / 144
; 		fontSize := 8
; 		distance := 4
; 		width := fontSize * unit * distance

; 		; Initialize settings
; 		this.Settings := {
; 			Grid: {
; 				ID: "Infos",
; 				Enabled: true,
; 				Columns: 1,
; 				Rows: Floor(A_ScreenHeight / (fontSize * 2)),
; 				Spacing: 5
; 			},
; 			Position: {
; 				; Mode: "Grid",
; 				X: 0,
; 				Y: 0
; 			},
; 			Size: {
; 				Width: width,
; 				Height: fontSize * 2
; 			},
; 			Font: {
; 				Name: "Consolas",
; 				Size: fontSize,
; 				Quality: 5,
; 				Color: "cBlue"
; 			},
; 			Colors: {
; 				Background: "0xA2AAAD",
; 				Text: "000000"
; 			},
; 			Margins: {
; 				X: 0,
; 				Y: 0
; 			},
; 			Styles: "+AlwaysOnTop -Caption +ToolWindow",
; 			Limits: {
; 				MaxNumberedHotkeys: 12,
; 				MaxWidthInChars: 110
; 			}
; 		}
; 	}

; 	__text := ""
; 	text {
; 		get => this.__text
; 		set => this.__text := value
; 	}

; 	__New(text, autoCloseTimeout := 0) {
; 		this.text := text
; 		this.timeout := autoCloseTimeout
; 		this.box := InfoBox(Infos.Settings)
		
; 		if (this.box) {
; 			this.CreateContent()
; 			this.SetupEvents()
; 			this.Show()

; 			if (this.timeout > 0) {
; 				SetTimer(() => this.Destroy(), -this.timeout)
; 			}
; 		}
; 	}

; 	CreateContent() {
; 		this.control := this.box.AddControl("Text", "Center", this._FormatText())
; 	}

; 	_FormatText() {
; 		ftext := String(this.text)
; 		lines := StrSplit(ftext, "`n")
		
; 		if (lines.Length > 1) {
; 			ftext := this._FormatByLine(lines)
; 		} else {
; 			ftext := this._LimitWidth(ftext)
; 		}

; 		return StrReplace(ftext, "&", "&&")
; 	}

; 	_FormatByLine(lines) {
; 		newLines := []
; 		for line in lines {
; 			newLines.Push(this._LimitWidth(line))
; 		}
; 		return newLines.Join("`n")
; 	}

; 	_LimitWidth(text) {
; 		if (StrLen(text) < Infos.Settings.Limits.MaxWidthInChars) {
; 			return text
; 		}
		
; 		insertions := 0
; 		while ((insertions + 1) * Infos.Settings.Limits.MaxWidthInChars + insertions) < StrLen(text) {
; 			insertions++
; 			text := text.Insert("`n", insertions * Infos.Settings.Limits.MaxWidthInChars + insertions)
; 		}
; 		return text
; 	}

; 	SetupEvents() {
; 		; Click to close
; 		this.control.OnEvent("Click", (*) => this.Destroy())
		
; 		; Function key hotkeys if in range
; 		if (this.box.position.row > 0 && this.box.position.row <= Infos.Settings.Limits.MaxNumberedHotkeys) {
; 			HotIfWinActive("ahk_id " this.box.gui.Hwnd)
; 			Hotkey("F" this.box.position.row, (*) => this.Destroy())
; 		}
; 	}

; 	Show() => this.box.Show()
; 	Destroy() => this.box.Destroy()
; 	static DestroyAll() => InfoBox.DestroyAll()
; }

/**
 * @class CleanInputBox
 * @description Clean input box with centered positioning
 */
/*
class CleanInputBox {
	static __New() {
		; Initialize settings
		this.Settings := {
			Grid: {
				ID: "CleanInputBox",
				Enabled: false,
				Columns: 1,
				Rows: 1,
				Spacing: 10
			},
			Position: {
				Mode: "Center",
				TopMargin: Round(A_ScreenHeight / 1080 * 800)
			},
			Size: {
				Width: Round(A_ScreenWidth / 3),
				Height: 30
			},
			Font: {
				Name: "Consolas",
				Size: 12,
				Quality: 5,
				Color: "cBlue"
			},
			Colors: {
				Background: "0xA2AAAD",
				Text: "000000"
			},
			Margins: {
				X: 0,
				Y: 0
			},
			Styles: "+AlwaysOnTop -Caption +ToolWindow",
			Input: {
				MinChars: 2,
				MaxMatches: 5,
				ShowMatchList: true
			}
		}
	}

	Input := ""
	IsWaiting := true

	__New(suggestions := []) {
		this.suggestions := suggestions
		this.box := InfoBox(CleanInputBox.Settings)
		
		if (this.box) {
			this.CreateContent()
			this.SetupEvents()
			this.Show()
		}
	}

	CreateContent() {
		this.control := this.box.AddControl("Edit", 
			"x0 Center -E0x200 w" this.box.settings.Size.Width)

		if (this.suggestions.Length > 0) {
			AutoComplete.Enhance(this.control, this.suggestions, {
				MaxMatches: this.box.settings.Input.MaxMatches,
				MinChars: this.box.settings.Input.MinChars,
				ShowMatchList: this.box.settings.Input.ShowMatchList
			})
		}
	}

	SetupEvents() {
		HotIfWinActive("ahk_id " this.box.gui.Hwnd)
		Hotkey("Enter", (*) => this.SetInput())
		Hotkey("CapsLock", (*) => this.SetCancel())
	}

	SetInput() {
		this.Input := this.control.Text
		this.IsWaiting := false
		this.Destroy()
	}

	SetCancel() {
		this.IsWaiting := false
		this.Destroy()
	}

	Show() => this.box.Show()
	Destroy() => this.box.Destroy()

	WaitForInput() {
		while this.IsWaiting {
			Sleep(10)
		}
		return this.Input
	}

	static WaitForInput() {
		inputBox := CleanInputBox()
		return inputBox.WaitForInput()
	}
}
*/
; Info(text, timeout?) => Infos(text, timeout ?? 2000)
Info(text, timeout?) => Infos(text, timeout ?? 10000)

/**
 * @class UnifiedDisplayManager
 * @description Manages stacked GUI displays with consistent positioning and styling
 * @version 1.0.0
 * @date 2024/02/16
 */
class UnifiedDisplayManager {
	; Static properties for display configuration
	static Instances := Map()
	static InstanceCount := 0
	static DefaultSettings := {
		Width: Round(A_ScreenWidth / 3),
		TopMargin: Round(A_ScreenHeight / 2),
		StackMargin: 30,
		Styles: "+AlwaysOnTop -Caption +ToolWindow",
		Font: {
			Name: "Consolas",
			Size: 10,
			Quality: 5
		},
		Colors: {
			Background: "0x161821",
			Text: "cBlue"
		}
	}

	; Instance properties
	Gui := ""
	Input := ""
	IsWaiting := true
	Settings := Map()
	Controls := Map()

	/**
	 * @constructor
	 * @param {Object} options Configuration options
	 */
	__New(options := {}) {
		this.InitializeSettings(options)
		this.CreateGui()
		UnifiedDisplayManager.InstanceCount++
		UnifiedDisplayManager.Instances[this.Gui.Hwnd] := this
	}

	InitializeSettings(options) {
		; Merge provided options with defaults
		this.Settings := UnifiedDisplayManager.DefaultSettings.Clone()
		for key, value in options.OwnProps() {
			if IsObject(this.Settings.%key%) && IsObject(value)
				this.Settings.%key% := this.MergeObjects(this.Settings.%key%, value)
			else
				this.Settings.%key% := value
		}
	}

	MergeObjects(target, source) {
		for key, value in source.OwnProps() {
			if IsObject(value) && IsObject(target.%key%)
				target.%key% := this.MergeObjects(target.%key%, value)
			else
				target.%key% := value
		}
		return target
	}

	CreateGui() {
		; Create base GUI with specified styles
		this.Gui := Gui(this.Settings.Styles)
		this.Gui.BackColor := this.Settings.Colors.Background
		this.Gui.SetFont("s" this.Settings.Font.Size " q" this.Settings.Font.Quality,
						this.Settings.Font.Name)

		; Setup default GUI events
		this.Gui.OnEvent("Close", (*) => this.Destroy())
		this.Gui.OnEvent("Escape", (*) => this.Destroy())
	}

	AddControl(type, options, text := "") {
		control := this.Gui.Add(type, options, text)
		this.Controls[control.Hwnd] := control
		return control
	}

	AddEdit(options := "", text := "") {
		return this.AddControl("Edit", "x0 Center -E0x200 Background" this.Settings.Colors.Background 
			" w" this.Settings.Width " " options, text)
	}

	AddComboBox(options := "", items := "") {
		if IsObject(items) {
			items := this.ProcessItems(items)
		}
		return this.AddControl("ComboBox", "x0 Center w" this.Settings.Width " " options, items)
	}

	ProcessItems(items) {
		result := []
		if Type(items) = "Array"
			result := items
		else if Type(items) = "Map" || Type(items) = "Object"
			for key, value in items
				result.Push(IsObject(value) ? key : value)
		return result
	}

	Show(params := "") {
		defaultPos := "y" this.CalculateYPosition() " w" this.Settings.Width
		this.Gui.Show(params ? params : defaultPos)
	}

	CalculateYPosition() {
		basePos := this.Settings.TopMargin
		stackOffset := (UnifiedDisplayManager.InstanceCount - 1) * this.Settings.StackMargin
		return basePos + stackOffset
	}

	/**
	 * @method WaitForInput
	 * @description Blocks until input is received
	 * @returns {String} The input received
	 */
	WaitForInput() {
		this.Show()
		while this.IsWaiting {
			Sleep(10)
		}
		return this.Input
	}

	SetInput(value) {
		this.Input := value
		this.IsWaiting := false
	}

	RegisterHotkey(hotkeyStr, callback) {
		HotIfWinActive("ahk_id " this.Gui.Hwnd)
		Hotkey(hotkeyStr, callback)
	}

	Destroy() {
		; Clean up hotkeys
		HotIfWinActive("ahk_id " this.Gui.Hwnd)
		Hotkey("Enter", "Off")
		HotIf()

		; Remove from instances
		UnifiedDisplayManager.Instances.Delete(this.Gui.Hwnd)
		UnifiedDisplayManager.InstanceCount--

		; Destroy GUI
		this.Gui.Destroy()
	}

	/**
	 * @method EnableAutoComplete
	 * @description Enables autocomplete functionality for an input control
	 * @param {Gui.Control} control The control to enable autocomplete for
	 * @param {Array|Map|Object} source The data source for autocomplete
	 */
	EnableAutoComplete(control, source) {
		; Process source data into a consistent format
		items := this.ProcessItems(source)
		
		; Bind autocomplete handler
		control.OnEvent("Change", (*) => this.HandleAutoComplete(control, items))
	}

	HandleAutoComplete(control, items) {
		static CB_GETEDITSEL := 320, CB_SETEDITSEL := 322
		
		if ((GetKeyState("Delete")) || (GetKeyState("Backspace")))
			return

		currContent := control.Text
		if (!currContent)
			return

		; Check for exact match
		for item in items {
			if (item = currContent)
				return
		}

		; Try to find matching item
		try {
			if (ControlChooseString(currContent, control) > 0) {
				start := StrLen(currContent)
				end := StrLen(control.Text)
				PostMessage(CB_SETEDITSEL, 0, this.MakeLong(start, end),, control.Hwnd)
			}
		}
	}

	MakeLong(low, high) => (high << 16) | (low & 0xffff)
}

; ---------------------------------------------------------------------------

class GuiButtonProperties {
	static SetButtonWidth(input, bMargin := 1) {
		largestLength := 0

		if Type(input) = 'String' {
			return largestLength := StrLen(input)
		} else if Type(input) = 'Array' {
			for value in input {
				currentLength := StrLen(value)
				if (currentLength > largestLength) {
					largestLength := currentLength
				}
			}
		} else if Type(input) = 'Map' || Type(input) = 'Object' {
			for key, value in input {
				currentLength := StrLen(value)
				if (currentLength > largestLength) {
					largestLength := currentLength
				}
			}
		}

		return GuiButtonProperties.CalculateButtonWidth(largestLength, bMargin)
	}

	; Function to set button length based on various input types
	static SetButtonLength(input) {
		largestLength := 0

		if Type(input) = 'String' {
			return StrLen(input)
		} else if Type(input) = 'Array' {
			for value in input {
				currentLength := StrLen(value)
				if (currentLength > largestLength) {
					largestLength := currentLength
				}
			}
		} else if Type(input) = 'Map' || Type(input) = 'Object' {
			for key, value in input {
				currentLength := StrLen(value)
				if (currentLength > largestLength) {
					largestLength := currentLength
				}
			}
		} else if Type(input) = 'String' && (SubStr(input, -4) = '.json' || SubStr(input, -3) = '.ini') {
			; Read from JSON or INI file and process
			; (Implementation depends on file format and structure)
		}

		return largestLength
	}

	static CalculateButtonWidth(textLength, bMargin := 7.5) {
		; Using default values instead of FontProperties
		avgCharWidth := 6  ; Approximate average character width
		; fontSize := 9      ; Default font size
		fontSize := 1      ; Default font size
		return Round((textLength * avgCharWidth) + (2 * (bMargin * fontSize)))
	}

	static SetButtonHeight(rows := 1, vMargin := 7.5) {
		; Using default values instead of FontProperties
		fontSize := 15      ; Default font size
		return Round((fontSize * vMargin) * rows)
	}

	static GetButtonDimensions(text, options := {}) {
		width := options.HasProp('width') ? options.width : GuiButtonProperties.CalculateButtonWidth(StrLen(text))
		height := options.HasProp('height') ? options.height : GuiButtonProperties.SetButtonHeight()
		return {width: width, height: height}
	}

	static GetOptimalButtonLayout(totalButtons, containerWidth, containerHeight) {
		buttonDimensions := this.GetButtonDimensions('Sample')
		maxColumns := Max(1, Floor(containerWidth / buttonDimensions.width))
		maxRows := Max(1, Floor(containerHeight / buttonDimensions.height))

		columns := Min(maxColumns, totalButtons)
		columns := Max(1, columns)  ; Ensure columns is at least 1
		rows := Ceil(totalButtons / columns)

		if (rows > maxRows) {
			rows := maxRows
			columns := Ceil(totalButtons / rows)
		}

		return {rows: rows, columns: columns}
	}
}

class FontProperties extends Gui {
	static Defaults := Map(
		'Name', 'Segoe UI',
		'Size', 9,
		'Weight', 400,
		'Italic', false,
		'Underline', false,
		'Strikeout', false,
		'Quality', 5,  ; 5 corresponds to CLEARTYPE_QUALITY
		'Charset', 1   ; 1 corresponds to DEFAULT_CHARSET
	)

	static GetDefault(key) {
		return this.Defaults.Has(key) ? this.Defaults[key] : ''
	}

	__New(guiObj := '') {
		this.LoadDefaults()
		if (guiObj != '') {
			this.UpdateFont(guiObj)
		}
		this.AvgCharW := this.CalculateAverageCharWidth()
	}

	LoadDefaults() {
		for key, value in FontProperties.Defaults {
			this.%key% := value
		}
	}

	UpdateFont(guiObj) {
		if !(guiObj is Gui) {
			return
		}

		hFont := SendMessage(0x31, 0, 0,, 'ahk_id ' guiObj.Hwnd)
		if (hFont = 0) {
			return
		}
		
		LOGFONT := Buffer(92, 0)
		if (!DllCall('GetObject', 'Ptr', hFont, 'Int', LOGFONT.Size, 'Ptr', LOGFONT.Ptr)) {
			return
		}
	
		this.Name := StrGet(LOGFONT.Ptr + 28, 32, 'UTF-16')
		this.Size := -NumGet(LOGFONT, 0, 'Int') * 72 / A_ScreenDPI
		this.Weight := NumGet(LOGFONT, 16, 'Int')
		this.Italic := NumGet(LOGFONT, 20, 'Char') != 0
		this.Underline := NumGet(LOGFONT, 21, 'Char') != 0
		this.Strikeout := NumGet(LOGFONT, 22, 'Char') != 0
		this.Quality := NumGet(LOGFONT, 26, 'Char')
		this.Charset := NumGet(LOGFONT, 23, 'Char')

		this.AvgCharW := this.CalculateAverageCharWidth()
	}

	CalculateAverageCharWidth() {
		hdc := DllCall('GetDC', 'Ptr', 0, 'Ptr')
		if (hdc == 0) {
			return 8  ; Default fallback value
		}

		hFont := DllCall('CreateFont'
			, 'Int', this.Size
			, 'Int', 0
			, 'Int', 0
			, 'Int', 0
			, 'Int', this.Weight
			, 'Uint', this.Italic
			, 'Uint', this.Underline
			, 'Uint', this.Strikeout
			, 'Uint', this.Charset
			, 'Uint', 0
			, 'Uint', 0
			, 'Uint', 0
			, 'Uint', 0
			, 'Str', this.Name)

		if (hFont == 0) {
			DllCall('ReleaseDC', 'Ptr', 0, 'Ptr', hdc)
			return 8  ; Default fallback value
		}

		hOldFont := DllCall('SelectObject', 'Ptr', hdc, 'Ptr', hFont)
		textMetrics := Buffer(56)
		if (!DllCall('GetTextMetrics', 'Ptr', hdc, 'Ptr', textMetrics)) {
			DllCall('SelectObject', 'Ptr', hdc, 'Ptr', hOldFont)
			DllCall('DeleteObject', 'Ptr', hFont)
			DllCall('ReleaseDC', 'Ptr', 0, 'Ptr', hdc)
			return 8  ; Default fallback value
		}

		averageCharWidth := NumGet(textMetrics, 20, 'Int')

		DllCall('SelectObject', 'Ptr', hdc, 'Ptr', hOldFont)
		DllCall('DeleteObject', 'Ptr', hFont)
		DllCall('ReleaseDC', 'Ptr', 0, 'Ptr', hdc)

		return averageCharWidth ? averageCharWidth : 8  ; Use fallback if averageCharWidth is 0
	}

	static CreateFontInfo(guiObj) {
		return FontProperties(guiObj)
	}
	static GetControlFontInfo(control) {
		if !(control is Gui.Control) {
			return FontProperties()
		}
		return FontProperties(control.Gui)
	}
}

class ErrorLogGui {
	logGui := {}
	logListView := {}
	logData := Map()
	logFile := 'error_log.json'
	instanceId := 0

	__New() {
		this.instanceId := this.GenerateUniqueId()
		this.CreateGui()
		this.LoadLogData()
	}
	
	AddTrayMenuItem() {
		A_TrayMenu.Add('Toggle ErrorLog Click-Through', (*) => this.MakeClickThrough())
	}

	MakeClickThrough() {
		static isClickThrough := false
		if (isClickThrough) {
			WinSetTransparent('Off', 'ahk_id ' . this.logGui.Hwnd)
			this.logGui.Opt('-E0x20')  ; Remove WS_EX_TRANSPARENT style
			isClickThrough := false
		} else {
			WinSetTransparent(255, 'ahk_id ' . this.logGui.Hwnd)
			this.logGui.Opt('+E0x20')  ; Add WS_EX_TRANSPARENT style
			isClickThrough := true
		}
	}

	GenerateUniqueId() {
		Loop {
			randomId := 'ErrorLogGui_' . Random(1, 9999)
			if (!WinExist('ahk_class AutoHotkeyGUI ahk_pid ' . DllCall('GetCurrentProcessId') . ' ' . randomId)) {
				return randomId
			}
		}
	}
	
	; CreateGui() {
	;     this.logGui := Gui('+Resize', 'Error Log - ' . this.instanceId)
	;     this.logGui.NeverFocusWindow()  ; This prevents the window from getting focus
	;     this.logGui.Opt('+LastFound')
	;     WinSetTitle(this.instanceId)
	;     this.logListView := this.logGui.Add('ListView', 'r20 w600 vLogContent', ['Timestamp', 'Message'])
	;     this.logGui.Add('Button', 'w100', 'Copy to Clipboard').OnEvent('Click', (*) => this.CopyToClipboard())
	;     this.logGui.OnEvent('Close', (*) => this.logGui.Hide())
	;     this.logGui.OnEvent('Size', (*) => this.ResizeControls())
	;     this.logGui.Show()
	; }
	
	CreateGui() {
		this.logGui := Gui('+Resize', 'Error Log - ' . this.instanceId)
		; this.logGui.NeverFocusWindow()  ; Using the new method
		; Gui2.NeverFocusWindow(this.logGui)
		this.logGui.Opt('+LastFound')
		WinSetTitle(this.instanceId)
		this.logListView := this.logGui.Add('ListView', 'r20 w600 vLogContent', ['Timestamp', 'Message'])
		this.logGui.Add('Button', 'w100', 'Copy to Clipboard').OnEvent('Click', (*) => this.CopyToClipboard())
		this.logGui.OnEvent('Close', (*) => this.logGui.Hide())
		this.logGui.OnEvent('Size', (*) => this.ResizeControls())
		this.logGui.Show()
	}
	
	ResizeControls() {
		clientPos := {}, h := w := 0
		if (this.logGui.Hwnd) {
			this.logGui.GetClientPos(,,&w, &h)
			clientPos.w := w
			clientPos.h := h
			; this.logListView.Move('w' . (clientPos.w - 20) . ' h' . (clientPos.h - 40))
			this.logListView.Move(,,(clientPos.w - 20) , (clientPos.h - 40))
		}
	}
	
	LoadLogData() {
		if (!FileExist(this.logFile)) {
			this.CreateDefaultLogFile()
		}
		
		try {
			fileContent := FileRead(this.logFile)
			loadedData := jsongo.Parse(fileContent)
			if (IsObject(loadedData) && loadedData.Length) {
				this.logData := Map()
				for entry in loadedData {
					this.logData.Set(entry.timestamp, entry.message)
				}
			}
		} catch as err {
			ErrorLogger.Log('Error loading log data: ' . err.Message)
			this.logData := Map()
		}
		
		this.UpdateListView()
	}
	
	CreateDefaultLogFile() {
		defaultData := [{timestamp: FormatTime(, 'yyyy-MM-dd HH:mm:ss'), message: 'Log file created'}]
		FileAppend(jsongo.Stringify(defaultData, 4), this.logFile)
	}
	
	; UpdateListView() {
	;     this.logListView.Delete()
	;     for timestamp, message in this.logData {
	;         this.logListView.Add(, timestamp, message)
	;     }
	;     this.logListView.ModifyCol()  ; Auto-size columns
	; }

	UpdateListView() {
		OutputDebug('LogData count: ' . this.logData.Count)
		OutputDebug('Updating ListView')
		this.logListView.Opt('-Redraw')  	; Suspend redrawing
		this.logListView.Delete()
		for timestamp, message in this.logData {
			this.logListView.Add(, timestamp, message)
		}
		this.logListView.ModifyCol()  		; Auto-size columns
		this.logListView.Opt('+Redraw')  	; Resume redrawing
	}
	
	; Log(message, showGui := true) {
	;     timestamp := FormatTime(, 'yyyy-MM-dd HH:mm:ss')
	;     this.logData.Set(timestamp, message)
		
	;     this.UpdateListView()
	;     this.SaveLogData()
	;     OutputDebug(timestamp . ': ' . message)
		
	;     if (showGui) {
	;         this.logGui.Show()
	;     }
	; }
	
	Log(input, showGui := true) {
		timestamp := FormatTime(, 'yyyy-MM-dd HH:mm:ss')
		
		if (IsObject(input)) {
			this.logData.Set(timestamp, input)
		} else {
			this.logData.Set(timestamp, {message: input})
		}
		
		this.UpdateGUI()
		this.SaveLogData()
		
		if (showGui) {
			this.logGui.Show()
		}
	}
	
	UpdateGUI() {
		if (this.logData.Count == 0) {
			return
		}
		
		; Get the first log entry to determine the structure
		firstEntry := this.logData[this.logData.Count]
		
		; Clear existing controls
		this.logGui.Destroy()
		
		; Recreate the GUI
		this.CreateBaseGUI()
		
		; Create headers based on the first entry
		headers := ['Timestamp']
		for key in firstEntry.OwnProps() {
			headers.Push(key)
		}
		
		; Create the ListView
		this.logListView := this.logGui.Add('ListView', 'r20 w600', headers)
		
		; Populate the ListView
		for timestamp, data in this.logData {
			row := [timestamp]
			for key, value in data.OwnProps() {
				row.Push(value)
			}
			this.logListView.Add(, row*)
		}
		
		this.logListView.ModifyCol()  ; Auto-size columns
		this.ResizeControls()
	}

	CreateBaseGUI() {
		this.logGui := Gui('+Resize', 'Error Log - ' . this.instanceId)
		; Gui2.NeverFocusWindow(this.logGui)
		this.logGui.NeverFocusWindow()
		this.logGui.OnEvent('Close', (*) => this.logGui.Hide())
		this.logGui.OnEvent('Size', (*) => this.ResizeControls())
	}

	DelayedUpdate() {
		this.UpdateListView()
		this.updatePending := false
	}

	; SaveLogData() {
	; 	try {
	; 		FileDelete(this.logFile)
	; 		dataToSave := []
	; 		for timestamp, message in this.logData {
	; 			dataToSave.Push({timestamp: timestamp, message: message})
	; 		}
	; 		FileAppend(jsongo.Stringify(dataToSave, 4), this.logFile)
	; 	} catch as err {
	; 		OutputDebug('Error saving log data: ' . err.Message)
	; 	}
	; }

	SaveLogData() {
		try {
			dataToSave := []
			for timestamp, message in this.logData {
				dataToSave.Push({timestamp: timestamp, message: message})
			}
			FileAppend(jsongo.Stringify(dataToSave, 4), this.logFile)
		} catch as err {
			try OutputDebug('Error saving log data: ' . err.Message)
			try Infos('Error saving log data: ' . err.Message)
		}
	}
	
	CopyToClipboard() {
		clipboardContent := ''
		for timestamp, message in this.logData {
			clipboardContent .= timestamp . ': ' . message . '`n'
		}
		A_Clipboard := clipboardContent
		MsgBox('Log data copied to clipboard!')
	}
}

; Static class to manage instances
class ErrorLogger {
	static instances := Map()
	; Define a static property for consistent property order
	static ErrorOrder := [
		"Message",
		"What",
		"Extra", 
		"File",
		"Line",
		"Stack"
	]

	static GetInstance(name := 'default') {
		if (!this.instances.Has(name)) {
			this.instances.Set(name, ErrorLogGui())
		}
		return this.instances.Get(name)
	}
	
	static Log(input, instanceName := 'default', showGui := true) {
		this.GetInstance(instanceName).Log(input, showGui)
	}

	/**
	 * @description Log error properties using OwnProps enumeration in specified order
	 * @param {Error} e The error object to log
	 * @returns {String} Formatted error message
	 */
	static errorProps(e) {
		props := ''
		; Loop through our desired order
		for propName in this.ErrorOrder {
			if e.HasProp(propName) && e.%propName% != '' {
				props .= Format("{1}: {2}`n", propName, e.%propName%)
			}
		}
		; ; Add any additional properties not in our ordered list
		; for prop in e.OwnProps() {
		; 	if !this.ErrorOrder.Has(prop) {
		; 		props .= Format("{1}: {2}`n", prop, e.%prop%)
		; 	}
		; }
		Infos("Error Properties [OwnProps()]:`n" props)
		return props
	}

	/**
	 * @description Log error using predefined property map in specified order
	 * @param {Error} e The error object to log
	 * @returns {String} Formatted error message
	 */
	static errorMap(e) {
		errorProps := Map(
			"Message", e.Message,
			"What", e.What,
			"Extra", e.Extra,
			"File", e.File,
			"Line", e.Line,
			"Stack", e.Stack
		)
		
		log := ''
		; Use the same order as defined in ErrorOrder
		for propName in this.ErrorOrder {
			if errorProps.Has(propName) && errorProps[propName] != '' {
				log .= Format("{1}: {2}`n", propName, errorProps[propName])
			}
		}
		Infos("Error Details [Map()]:`n" log)
		return log
	}
}

class FileSystemSearch extends Gui {

	/**
		* Find all the matches of your search request within the currently
		* opened folder in the explorer.
		* The searcher recurses into all the subfolders.
		* Will search for both files and folders.
		* After the search is completed, will show all the matches in a list.
		* Call StartSearch() after creating the class instance if you can pass
		* the input yourself.
		* Call GetInput() after creating the class instance if you want to have
		* an input box to type in your search into.
		*/
	__New(searchWhere?, caseSense := 'Off') {
		super.__New('+Resize', 'These files match your search:')

		Gui2.MakeFontNicer(14)
		Gui2.DarkMode(this)

		this.List := this.AddText(, '
		(
			Right click on a result to copy its full path.
			Double click to open it in explorer.
		)')

		this.WidthOffset  := 35
		this.HeightOffset := 80

		this.List := this.AddListView(
			'Count50 Background' this.BackColor,
			/**
				* Count50 — we're not losing much by allocating more memory
				* than needed,
				* and on the other hand we improve the performance by a lot
				* by doing so
				*/
			['File', 'Folder', 'Directory']
		)

		this.caseSense := caseSense

		if !IsSet(searchWhere) {
			this.ValidatePath()
		} else {
			this.path := searchWhere
		}

		this.SetOnEvents()
	}

	/**
		* Get an input box to type in your search request into.
		* Get a list of all the matches that you can open in explorer.
		*/
	GetInput() {
		if !input := CleanInputBox().WaitForInput() {
			return false
		}
		this.StartSearch(input)
	}

	ValidatePath() {
		SetTitleMatchMode('RegEx')
		try this.path := WinGetTitle('^[A-Z]: ahk_exe explorer\.exe')
		catch Any {
			Info('Open an explorer window first!')
			Exit()
		}
	}

	/**
		* Get a list of all the matches of *input*.
		* You can either open them in explorer or copy their path.
		* @param input *String*
		*/
	StartSearch(input) {
		/**
			* Improves performance rather than keeping on adding rows
			* and redrawing for each one of them
			*/
		this.List.Opt('-Redraw')

		;To remove the worry of 'did I really start the search?'
		gInfo := Infos('The search is in progress')

		if this.path ~= '^[A-Z]:\\$' {
			this.path := this.path[1, -2]
		}

		loop files this.path '\*.*', 'FDR' {
			if !A_LoopFileName.Find(input, this.caseSense) {
				continue
			}
			if A_LoopFileAttrib.Find('D')
				this.List.Add(, , A_LoopFileName, A_LoopFileDir)
			else if A_LoopFileExt
				this.List.Add(, A_LoopFileName, , A_LoopFileDir)
		}

		gInfo.Destroy()

		this.List.Opt('+Redraw')
		this.List.ModifyCol() ;It makes the columns fit the data — @rbstrachan

		this.Show('AutoSize')
	}

	DestroyResultListGui() {
		this.Minimize()
		this.Destroy()
	}

	SetOnEvents() {
		this.List.OnEvent('DoubleClick',
			(guiCtrlObj, selectedRow) => this.ShowResultInFolder(selectedRow)
		)
		this.List.OnEvent('ContextMenu',
			(guiCtrlObj, rowNumber, var:=0) => this.CopyPathToClip(rowNumber)
		)
		this.OnEvent('Size',
			(guiObj, minMax, width, height) => this.FixResizing(width, height)
		)
		this.OnEvent('Escape', (guiObj) => this.DestroyResultListGui())
	}

	FixResizing(width, height) {
		this.List.Move(,, width - this.WidthOffset, height - this.HeightOffset)
		/**
			* When you resize the main gui, the listview also gets resize to have the same
			* borders as usual.
			* So, on resize, the onevent passes *what* you resized and the width and height
			* that's now the current one.
			* Then you can use that width and height to also resize the listview in relation
			* to the gui
			*/
	}

	ShowResultInFolder(selectedRow) {
		try Run('explorer.exe /select,' this.GetPathFromList(selectedRow))
		/**
			* By passing select, we achieve the cool highlighting thing when the file / folder
			* gets opened. (You can pass command line parameters into the run function)
			*/
	}

	CopyPathToClip(rowNumber) {
		A_Clipboard := this.GetPathFromList(rowNumber)
		Info('Path copied to clipboard!')
	}

	GetPathFromList(rowNumber) {
		/**
			* The OnEvent passes which row we interacted with automatically
			* So we read the text that's on the row
			* And concoct it to become the full path
			* This is much better performance-wise than adding all the full paths to an array
			* while adding the listviews (in the loop) and accessing it here.
			* Arguably more readable too
			*/

		file := this.List.GetText(rowNumber, 1)
		dir  := this.List.GetText(rowNumber, 2)
		path := this.List.GetText(rowNumber, 3)

		return path '\' file dir ; No explanation required, it's just logic — @rbstrachan
	}
}

class FileSearch {
	static fso := ComObject('Scripting.FileSystemObject')

	__New(searchPath := A_WorkingDir) {
		this.searchPath := searchPath
	}

	Search(pattern := '', options := {}) {
		results := []
		this._SearchRecursive(this.searchPath, pattern, options, &results)
		sortBy := options.HasOwnProp('sortBy') ? options.sortBy : 'name'
		sortDesc := options.HasOwnProp('sortDesc') ? options.sortDesc : false
		return this._SortResults(results, sortBy, sortDesc)
	}

	_SearchRecursive(folder, pattern, options, &results) {
		for file in FileSearch.fso.GetFolder(folder).Files {
			if this._MatchesCriteria(file, pattern, options)
				results.Push({path: file.Path, name: file.Name, size: file.Size, dateModified: file.DateLastModified})
		}
		for subFolder in FileSearch.fso.GetFolder(folder).SubFolders
			this._SearchRecursive(subFolder.Path, pattern, options, &results)
	}

	_MatchesCriteria(file, pattern, options) {
		if pattern && !InStr(file.Name, pattern)
			return false
		if options.HasOwnProp('minSize') && file.Size < options.minSize
			return false
		if options.HasOwnProp('maxSize') && file.Size > options.maxSize
			return false
		if options.HasOwnProp('afterDate') && file.DateLastModified < options.afterDate
			return false
		if options.HasOwnProp('beforeDate') && file.DateLastModified > options.beforeDate
			return false
		return true
	}

	_SortResults(results, sortBy := 'name', sortDesc := false) {
		results.Sort((*) => this._CompareItems(&a, &b, sortBy, sortDesc))
		return results
	}
	
	_CompareItems(&a, &b, sortBy, sortDesc) {
		if (sortDesc)
			return a.%sortBy% > b.%sortBy% ? -1 : 1
		else
			return a.%sortBy% < b.%sortBy% ? -1 : 1
	}

	ShowResultsGUI(results) {
		; Implement GUI display similar to FileSystemSearch class
		Infos(results)
	}
}

#HotIf WinActive('ahk_class CabinetWClass')
; F3::{
; 	sel := []
; 	sel := getSelected()
; 	str := ''
; 	str := sel.ToString()
; 	len := sel.Length
; 	Infos(len '`n' str)
; }
F3::fileString()
fileString(&str?){
	sel := []
	sel := getSelected()
	str := ''
	str := sel.ToString()
	len := sel.Length
	; Infos(len '`n' str)
	return str
}
^+Enter::
^+LButton::{
	sel := []
	sel := ''
	sel := getSelected()
	len := sel.length
	; if len == 1 {
	if len >= 1 {
		sel := sel.ToString()
		Run(Paths.Code ' "' sel '"')
		; Infos('len == ' len)
	}
	else {
		for each, value in sel {
			Run(Paths.Code ' "' value '"')
			; Infos('I did this array to run.')
		}
	}
}
#HotIf

/**
 * 
 * @description..: Get the paths of selected files and folders both in Explorer and on the Desktop
 * @link 	GEV: https://www.autohotkey.com/boards/viewtopic.php?p=514288#p514288
 * @link	v2: https://www.autohotkey.com/boards/viewtopic.php?style=17&t=60403#p255256
 * @author 	v1: GEV, teadrinker
 * @author 	v2: mikeyww
*/
; ---------------------------------------------------------------------------
getSelected(hWnd := 0) { 
	Static SWC_DESKTOP := 8, SWFO_NEEDDISPATCH := 1
	winClass := WinGetClass(hWnd := WinActive('A'))
	If !(winClass ~= 'Progman|WorkerW|(Cabinet|Explore)WClass'){
		Return
	}
	shellWindows := ComObject('Shell.Application').Windows
	sel := []
	If !(winClass ~= 'Progman|WorkerW') {
		For window in shellWindows{
			If hWnd = window.HWND && shellFolderView := window.Document{
				Break
			}
		}
	}
	Else shellFolderView := shellWindows.FindWindowSW(0, 0, SWC_DESKTOP, 0, SWFO_NEEDDISPATCH).Document
	For item in shellFolderView.SelectedItems{
		sel.SafePush(item.Path)
	}
	Return sel
}

/*
    Github: https://github.com/Nich-Cebolla/AutoHotkey-LibV2/blob/main/GuiResizer.ahk
    Author: Nich-Cebolla
    Version: 1.0.0
    License: MIT
*/

class GuiResizer {
    static Last := ''
    /**
     * @description - Creates a callback function to be used with
     * `Gui.Prototype.OnEvent('Size', Callback)`. This function requires a bit of preparation. See
     * the longer explanation within the source document for more information. Note that
     * `GuiResizer` modifies the `Gui.Prototype.Show` method slightly. This is the change:
        @example
        Gui.Prototype.DefineProp('Show', {Call: _Show})
        _Show(Self) {
            Show := Gui.Prototype.Show
            this.JustShown := 1
            Show(Self)
        }
        @
     * @param {Gui} GuiObj - The GUI object that contains the controls to be resized.
     * @param {Integer} [Interval=33] - The interval at which resizing occurs after initiated. Once
     * the `Size` event has been raised, the callback is set to a timer that loops every `Interval`
     * milliseconds and the event handler is temporarily disabled. After the function detects that
     * no size change has occurred within `StopCount` iterations, the timer is disabled and the
     * event handler is re-enabled. For more control over the visual appearance of the display as
     * resizing occurs, set `SetWinDelay` in the Auto-Execute portion of your script.
     * {@link https://www.autohotkey.com/docs/v2/lib/SetWinDelay.htm}
     * @param {Integer} [StopCount=6] - The number of iterations that must occur without a size
     * change before the timer is disabled and the event handler is re-enabled.
     * @param {Boolean} [SetSizerImmediately=true] - If true, the `Size` event is raised immediately
     * after the object is created. When this is true, you can call `GuiResizer` like a function:
     * `GuiResizer(ControlsArr)`. If you do need the instance object in some other portion of the
     * code or at some expected later time, the last instance created is available on the class
     * object `GuiResizer.Last`.
     * @param {Integer} [UsingSetThreadDpiAwarenessContext=-2] - The DPI awareness context to use.
     * This is necessary as a parameter because, when using a THREAD_DPI_AWARENESS_CONTEXT other than
     * the default, AutoHotkey's behavior when returning values from built-in functions is
     * inconsistent unless the awareness context is set each time before calling the function.
     * Understand that if you leave the value at -4, the OS expects that you will handle DPI scaling
     * within your code. Set this parameter to 0 to disable THREAD_DPI_AWARENESS_CONTEXT.
     */
    __New(GuiObj, Interval := 100, StopCount := 6, SetSizerImmediately := true, UsingSetThreadDpiAwarenessContext := -2) {
        GuiResizer.Last := this
        this.DefineProp('_Resize', {Call: ObjBindMEthod(this, 'Resize')})
        GuiObj.DefineProp('Show', {Call: _Show})
        this.Interval := Interval
        this.ExpiredCtrls := []
        this.DeltaW := this.DeltaH := 0
        this.StopCount := StopCount
        this.GuiObj := GuiObj
        this.Active := {ZeroCount: 0, LastW: 0, LastH : 0}
        this.Size := []
        this.Move := []
        this.MoveAndSize := []
        this.CurrentDPI := this.DPI := DllCall("User32\GetDpiForWindow", "Ptr", GuiObj.Hwnd, "UInt")
        this.SetThreadDpiAwarenessContext := UsingSetThreadDpiAwarenessContext
        this.GuiObj.GetClientPos(, , &gw, &gh)
        this.Shown := DllCall('IsWindowVisible', 'Ptr', GuiObj.Hwnd)
        this.Active.W := gw
        this.Active.H := gh
        ; GuiResizer.OutputDebug(this, A_ThisFunc, A_LineNumber, , 'Gui initial size: W' gw ' H' gh)
        for Ctrl in GuiObj {
            if !Ctrl.HasOwnProp('Resizer')
                continue
            Resizer := Ctrl.Resizer, z := FlagSize := FlagMove := 0
            Ctrl.GetPos(&cx, &cy, &cw, &ch)
            Ctrl.Resizer.pos := {x: cx, y: cy, w: cw, h: ch}
            if Resizer.HasOwnProp('x')
                z += 1
            if Resizer.HasOwnProp('y')
                z += 2
            switch z {
                case 0:
                    Resizer.x := 0, Resizer.y := 0
                case 1:
                    Resizer.y := 0, FlagMove := 1
                case 2:
                    Resizer.x := 0, FlagMove := 1
                case 3:
                    FlagMove := 1
            }
            z := 0
            if Resizer.HasOwnProp('w')
                z += 1
            if Resizer.HasOwnProp('h')
                z += 2
            switch z {
                case 0:
                    Resizer.w := 0, Resizer.h := 0
                case 1:
                    Resizer.h := 0, FlagSize := 1
                case 2:
                    Resizer.w := 0, FlagSize := 1
                case 3:
                    FlagSize := 1
            }
            if FlagSize {
                if FlagMove
                    this.MoveAndSize.Push(Ctrl)
                else
                    this.Size.Push(Ctrl)
            } else if FlagMove
                this.Move.Push(Ctrl)
            else
                throw Error('A control has ``Resizer`` property, but the property does not have'
                '`r`na ``w``, ``h``, ``x``, or ``y`` property.', -1, 'Ctrl name: ' Ctrl.Name)

            _Show(Self) {
                Show := Gui.Prototype.Show
                this.JustShown := 1
                Show(Self)
            }
        }
        if SetSizerImmediately
            GuiObj.OnEvent('size', this)
    }

    Call(GuiObj, MinMax, Width, Height) {
        if !this.Shown {
            this.GuiObj.GetClientPos(,, &gw, &gh)
            if gw <= 20
                return
            this.Active.W := gw, this.Active.H := gh
            ; GuiResizer.OutputDebug(this, A_ThisFunc, A_LineNumber,
            ; , 'Gui shown for the first time. Size: W' gw ' H' gh)
            this.Shown := 1
        }
        if this.HasOwnProp('JustShown') {
            this.DeleteProp('JustShown')
            ; GuiResizer.OutputDebug(this, A_ThisFunc, A_LineNumber, , 'Gui just shown')
            return
        }
        DPI := DllCall("User32\GetDpiForWindow", "Ptr", this.GuiObj.Hwnd, "UInt")
        if this.DPI != DPI {
            ; GuiResizer.OutputDebug(this, A_ThisFunc, A_LineNumber,
            ; , 'Dpi changed. Old: ' this.DPI '`tNew: ' DPI '.')
            this.DPI := DPI
            return
        }
        this.GuiObj.OnEvent('Size', this, 0)
        ; GuiResizer.OutputDebug(this, A_ThisFunc, A_LineNumber, , 'Resize timer activated.')
        SetTimer(this._Resize, this.Interval)
        this.Resize()
    }

    IterateCtrlContainers(SizeCallback, MoveCallback, MoveAndResizeCallback) {
        for Ctrl in this.Size
            SizeCallback(Ctrl)
        for Ctrl in this.Move
            MoveCallback(Ctrl)
        for Ctrl in this.MoveAndSize
            MoveAndResizeCallback(Ctrl)
    }

    IterateAll(Callback) {
        this.IterateCtrlContainers(Callback, Callback, Callback)
    }

    Resize(*) {
        if this.SetThreadDpiAwarenessContext
            DllCall("SetThreadDpiAwarenessContext", "ptr", this.SetThreadDpiAwarenessContext, "ptr")
        this.GuiObj.GetClientPos(,, &gw, &gh)
        if !(gw - this.Active.LastW) && !(gh - this.Active.LastH) {
            ; GuiResizer.OutputDebug(this, A_ThisFunc, A_LineNumber,
            ; , 'No change since last tick. ZeroCount: ' this.Active.ZeroCount)
            if ++this.Active.ZeroCount >= this.StopCount {
                ; GuiResizer.OutputDebug(this, A_ThisFunc, A_LineNumber, , 'Disabling timer.')
                SetTimer(this._Resize, 0)
                if this.ExpiredCtrls.Length
                    this.HandleExpiredCtrls()
                this.GuiObj.OnEvent('Size', this)
            }
            return
        }
        this.DeltaW := gw - this.Active.W
        this.DeltaH := gh - this.Active.H
        ; GuiResizer.OutputDebug(this, A_ThisFunc, A_LineNumber,
        ; , 'Resize function ticked. Size: W' gw ' H' gh)
        this.IterateCtrlContainers(_Size, _Move, _MoveAndSize)
        this.Active.LastW := gw, this.Active.LastH := gh

        _Size(Ctrl) {
            if !Ctrl.HasOwnProp('Resizer') {
                this.ExpiredCtrls.Push(Ctrl)
                return
            }
            ; GuiResizer.OutputDebug(this, A_ThisFunc, A_LineNumber, Ctrl, 'Before')
            this.GetDimensions(Ctrl, &W, &H)
            Ctrl.Move(,, W, H)
            ; GuiResizer.OutputDebug(this, A_ThisFunc, A_LineNumber, Ctrl, 'After')
        }

        _Move(Ctrl) {
            if !Ctrl.HasOwnProp('Resizer') {
                this.ExpiredCtrls.Push(Ctrl)
                return
            }
            ; GuiResizer.OutputDebug(this, A_ThisFunc, A_LineNumber, Ctrl, 'Before')
            this.GetCoords(Ctrl, &X, &Y)
            Ctrl.Move(X, Y)
            ; GuiResizer.OutputDebug(this, A_ThisFunc, A_LineNumber, Ctrl, 'After')
        }

        _MoveAndSize(Ctrl) {
            if !Ctrl.HasOwnProp('Resizer') {
                this.ExpiredCtrls.Push(Ctrl)
                return
            }
            ; GuiResizer.OutputDebug(this, A_ThisFunc, A_LineNumber, Ctrl, 'Before')
            this.GetCoords(Ctrl, &X, &Y), this.GetDimensions(Ctrl, &W, &H)
            Ctrl.Move(X, Y, W, H)
            ; GuiResizer.OutputDebug(this, A_ThisFunc, A_LineNumber, Ctrl, 'After')
        }
    }

    GetCoords(Ctrl, &X, &Y) {
        Resizer := Ctrl.Resizer, Pos := Resizer.Pos
        X := Resizer.X ? this.DeltaW * Resizer.X + Pos.X : Pos.X
        if X < 0
            X := 0
        Y := Resizer.Y ? this.DeltaH * Resizer.Y + Pos.Y : Pos.Y
        if Y < 0
            Y := 0
    }

    GetDimensions(Ctrl, &W, &H) {
        Resizer := Ctrl.Resizer, Pos := Resizer.Pos
        W := Resizer.W ? this.DeltaW * Resizer.W + Pos.W : Pos.W
        if W < 0
            W := 0
        H := Resizer.H ? this.DeltaH * Resizer.H + Pos.H : Pos.H
        if H < 0
            H := 0
    }

    HandleExpiredCtrls() {
        for Ctrl in this.ExpiredCtrls {
            FlagRemoved := 0
            for Container in [this.Size, this.Move, this.MoveAndSize] {
                for _Ctrl in Container {
                    if Ctrl.Name == _Ctrl.Name {
                        Container.RemoveAt(A_Index)
                        FlagRemoved := 1
                        break
                    }
                }
                if FlagRemoved
                    break
            }
            if FlagRemoved
                break
        }
    }

    /**
     * @description - Assigns the appropriate parameters to controls that are adjacent to one another.
     * The input controls must be aligned along one dimension; this method will not function as
     * expected if some are above others and also some are to the left or right of others. They must
     * be adjacent along a single axis. Use this when you have a small number of controls that you
     * want to be resized along with the GUI window. Be sure to handle any surrounding controls
     * so they don't overlap.
     * Here's some examples:

        ||||| ||||| |||||             |     |||||||
        ||||| ||||| |||||     - OK    |     |||||||         |||||   - NOT OK
        ||||| ||||| |||||             |     |||||||         |||||
        _________________             |     |||||||
        ||||        ||||              |
        ||||        ||||     - OK     |         |||||
        ||||                          |         |||||
              ||||                    |         |||||
              ||||                    |
              ||||                    |
                                      |
        @example
            ; You can run this example to see what it looks like
            GuiObj := Gui('+Resize -DPIScale')
            Controls := []
            Loop 4
                Controls.Push(GuiObj.Add('Edit', Format('x{} y{} w{} h{} vEdit{}'
                , 10 + 220 * (A_Index - 1), 10, 200, 400, A_Index)))
            GuiResizer.SetAdjacentControls(Controls)
            GuiResizer(GuiObj)
            GuiObj.Show()
        @
     * @param {Array} Controls - An array of controls to assign the appropriate parameters to.
     * @param {Boolean} Vertical - If true, the controls are aligned vertically; otherwise, they are aligned horizontally.
     * @param {Boolean} IncludeOpposite - If true, the opposite side of the control will be set to 1; otherwise, it will be set to 0.
     * @returns {Void}
     */
    static SetAdjacentControls(Controls, Vertical := false, IncludeOpposite := true) {
        static Letters := Map('X', 'H', 'Y', 'W', '_X', 'W', '_Y', 'H')
        local Count := Controls.Length, Result := [], CDF := [], Order := []
        , X := Y := W := H := 0
        if Controls.Length < 2 {
            if Controls.Length
                Controls.Resizer := {w: 1, h: 1}, Result.Push(Controls)
            return
        }
        if Vertical
            _Refactored('Y')
        else
            _Refactored('X')

        _Refactored(X_Or_Y) {
            _GetCDF(1 / Count), Proportion := 1 / Count, _GetOrder(X_Or_Y)
            for Ctrl in Order
                Ctrl.Resizer := {}, Ctrl.Resizer.%Letters['_' X_Or_Y]% := Proportion, Ctrl.Resizer.%X_Or_Y% := CDF[A_Index]
                , Ctrl.Resizer.%Letters[X_Or_Y]% := IncludeOpposite ? 1 : 0
        }
        _GetCDF(Step) {
            Loop Count
                CDF.Push(Step * (A_Index - 1))
        }
        _GetOrder(X_Or_Y) {
            for Ctrl in Controls {
                Ctrl.GetPos(&x, &y, &w, &h)
                Ctrl.__Resizer := {x: x, y: y}
                Order.Push(Ctrl)
            }
            InsertionSort(Order, 1, , ((X_Or_Y, a, b) => a.__Resizer.%X_Or_Y% - b.__Resizer.%X_Or_Y%).Bind(X_Or_Y))
            InsertionSort(arr, start, end?, compareFn := (a, b) => a - b) {
                i := start - 1
                while ++i <= (end??arr.Length) {
                    current := arr[i]
                    j := i - 1
                    while (j >= start && compareFn(arr[j], current) > 0) {
                        arr[j + 1] := arr[j]
                        j--
                    }
                    arr[j + 1] := current
                }
                return arr
            }
        }
    }

    /**
     * @description - Returns an integer representing the position of the first object relative
     * to the second object. This function assumes that the two objects do not overlap.
     * The inputs can be any of:
     * - A Gui object, Gui.Control object, or any object with an `Hwnd` property.
     * - An object with properties { L, T, R, B }.
     * - An Hwnd of a window or control.
     * @param {Integer|Object} Subject - The subject of the comparison. The return value indicates
     * the position of this object relative to the other.
     * @param {Integer|Object} Target - The object which the subject is compared to.
     * @returns {Integer} - Returns an integer representing the relative position shared between two objects.
     * The values are:
     * - 1: Subject is completely above target and completely to the left of target.
     * - 2: Subject is completely above target and neither completely to the right nor left of target.
     * - 3: Subject is completely above target and completely to the right of target.
     * - 4: Subject is completely to the right of target and neither completely above nor below target.
     * - 5: Subject is completely to the right of target and completely below target.
     * - 6: Subject is completely below target and neither completely to the right nor left of target.
     * - 7: Subject is completely below target and completely to the left of target.
     * - 8: Subject is completely below target and completely to the left of target.
     */
    static GetRelativePosition(Subject, Target) {
        _Get(Subject, &L1, &T1, &R1, &B1)
        _Get(Target, &L2, &T2, &R2, &B2)
        if L1 < L2 && R1 < L2 {
            if B1 < T2
                return 1
            else if T1 > B2
                return 7
            else
                return 8
        } else if T1 < T2 && B1 < T2 {
            if L1 > R2
                return 3
            else
                return 2
        } else if L1 < R2
            return 6
        else if T1 < B2
            return 4
        else
            return 5

        _Get(Input, &L, &T, &R, &B) {
            if IsObject(Input) {
                if !Input.HasOwnProp('Hwnd') {
                    L := Input.L, T := Input.T, R := Input.R, B := Input.B
                    return
                }
                WinGetPos(&L, &T, &W, &H, Input.Hwnd)
            } else
                WinGetPos(&L, &T, &W, &H, Input)
            R := L + W, B := T + H
        }
    }

    static OutputDebug(Resizer, Fn, Line, Ctrl?, Extra?) {
        if IsSet(Ctrl) {
            Ctrl.GetPos(&cx, &cy, &cw, &ch)
            OutputDebug('`n'
                Format(
                    'Function: {1}`tLine: {2}'
                    '`nControl: {3}'
                    '`nX: {4}`tY: {5}`tW: {6}`tH: {7}'
                    '`nDeltaW: {8}`tDeltaH: {9}'
                    '`nActiveW: {10}`tActiveH: {11}`tLastW: {12}`tLastH: {13}'
                    '`nExtra: {14}'
                    , Fn, Line, Ctrl.Name, cx, cy, cw, ch, Resizer.DeltaW, Resizer.DeltaH, Resizer.Active.W
                    , Resizer.Active.H, Resizer.Active.LastW, Resizer.Active.LastH, Extra ?? ''
                )
            )
        } else {
            OutputDebug('`n'
                Format(
                    'Function: {1}`tLine: {2}'
                    '`nDeltaW: {3}`tDeltaH: {4}'
                    '`nActiveW: {5}`tActiveH: {6}`tLastW: {7}`tLastH: {8}'
                    '`nExtra: {9}'
                    , Fn, Line, Resizer.DeltaW, Resizer.DeltaH, Resizer.Active.W, Resizer.Active.H
                    , Resizer.Active.LastW, Resizer.Active.LastH, Extra ?? ''
                )
            )
        }
    }
}

GuiResizer.Prototype.Base := GuiResizer2
; ---------------------------------------------------------------------------
/**
 * GuiReSizer - A class to handle GUI resizing and control layout management
 * @class
 * @author Fanatic Guru, enhanced by OvercastBTC
 * @version 2024.03.15
 * @description Manages the resizing of GUI windows and repositioning of controls
 * @requires AutoHotkey v2.0.2+
 * @example
 * ; Basic usage
 * myGui := Gui()
 * myGui.OnEvent("Size", GuiReSizer) 
 */
class GuiReSizer2 {
	
	#Requires AutoHotkey v2.0.2+
	
	; Static class properties
	static VERSION := "2024.03.15"
	static AUTHOR := "Fanatic Guru"
	
	; Property definitions with validation
	static Properties := {
		X: "number",          ; X positional offset 
		Y: "number",          ; Y positional offset
		XP: "number",         ; X position as percentage
		YP: "number",         ; Y position as percentage
		Width: "number",      ; Width of control
		Height: "number",     ; Height of control
		WidthP: "number",     ; Width as percentage
		HeightP: "number",    ; Height as percentage
		MinX: "number",       ; Minimum X offset
		MaxX: "number",       ; Maximum X offset
		MinY: "number",       ; Minimum Y offset
		MaxY: "number",       ; Maximum Y offset
		MinWidth: "number",   ; Minimum control width
		MaxWidth: "number",   ; Maximum control width
		MinHeight: "number",  ; Minimum control height
		MaxHeight: "number",  ; Maximum control height
		Cleanup: "boolean",   ; Redraw control flag
		AnchorIn: "boolean"   ; Restrict to anchor bounds
	}

	; Constructor 
	__New() {
		this.InitializeProperties()
	}

	; Initialize default property values
	InitializeProperties() {
		; for prop, type in GuiReSizer.Properties {
		for prop, type in GuiReSizer2.Properties {
			switch type {
				case "number": this.%prop% := 0
				case "boolean": this.%prop% := false
				default: this.%prop% := ""
			}
		}
	}

	; Cleanup method
	__Delete() {
		try {
			; Clean up any resources
			this.RemoveEventHandlers()
		}
		catch as err {
			throw ValueError("GuiReSizer cleanup failed: " err.Message)
		}
	}

	/**
	 * Convert object to string representation
	 * @returns {String} String representation of GuiReSizer
	 */
	ToString() {
		try {
			return Format("GuiReSizer [v{1}] - Controls:{2}", this.VERSION)
		}
		catch as err {
			throw ValueError("ToString failed: " err.Message)
		}
	}

	/**
	 * Convert to JSON format for serialization
	 * @returns {String} JSON representation
	 */
	ToJSON() {
		try {
			props := {}
			; for prop in GuiReSizer.Properties {
			for prop in GuiReSizer2.Properties {
				if this.HasProp(prop) {
					props.%prop% := this.%prop%
				}
			}
			return JSON.Stringify(props)
		}
		catch as err {
			throw ValueError("JSON conversion failed: " err.Message) 
		}
	}
	;{ Call GuiReSizer
	Static Call(GuiObj, WindowMinMax, GuiW, GuiH) {
		;{ Initial display of Gui use redraw to cleanup first positioning
		Try
			(GuiObj.Init)
		Catch
			GuiObj.Init := 3 ; Redraw twice and initialize abbreviations on Initial Call (called on initial Show)
		;}
		;{ Window minimize and maximize
		If WindowMinMax = -1 ; Do nothing if window minimized
			Return
		If WindowMinMax = 1 ; Repeat if maximized
			Repeat := true
		;}
		;{ Loop through all Controls of Gui
		Loop 2 { ; Loop twice by default to calculate Anchor controls
			For Hwnd, CtrlObj in GuiObj {
				;{ Initializations on First Call
				If GuiObj.Init = 3 {
					Try CtrlObj.OriginX := CtrlObj.OX
					Try CtrlObj.OriginXP := CtrlObj.OXP
					Try CtrlObj.OriginY := CtrlObj.OY
					Try CtrlObj.OriginYP := CtrlObj.OYP
					Try CtrlObj.Width := CtrlObj.W
					Try CtrlObj.WidthP := CtrlObj.WP
					Try CtrlObj.Height := CtrlObj.H
					Try CtrlObj.HeightP := CtrlObj.HP
					Try CtrlObj.MinWidth := CtrlObj.MinW
					Try CtrlObj.MaxWidth := CtrlObj.MaxW
					Try CtrlObj.MinHeight := CtrlObj.MinH
					Try CtrlObj.MaxHeight := CtrlObj.MaxH
					Try CtrlObj.Function := CtrlObj.F
					Try CtrlObj.Cleanup := CtrlObj.C
					Try CtrlObj.Anchor := CtrlObj.A
					Try CtrlObj.AnchorIn := CtrlObj.AI
					If !CtrlObj.HasProp("AnchorIn")
						CtrlObj.AnchorIn := true
				}
				;}
				;{ Initialize Current Positions and Sizes
				CtrlObj.GetPos(&CtrlX, &CtrlY, &CtrlW, &CtrlH)
				LimitX := AnchorW := GuiW, LimitY := AnchorH := GuiH, OffsetX := OffsetY := 0
				;}
				;{ Check for Anchor
				If CtrlObj.HasProp("Anchor") {
					Repeat := true
					CtrlObj.Anchor.GetPos(&AnchorX, &AnchorY, &AnchorW, &AnchorH)
					If CtrlObj.HasProp("X") or CtrlObj.HasProp("XP")
						OffsetX := AnchorX
					If CtrlObj.HasProp("Y") or CtrlObj.HasProp("YP")
						OffsetY := AnchorY
					If CtrlObj.AnchorIn
						LimitX := AnchorW, LimitY := AnchorH
				}
				;}
				;{ OriginX
				If CtrlObj.HasProp("OriginX") and CtrlObj.HasProp("OriginXP")
					OriginX := CtrlObj.OriginX + (CtrlW * CtrlObj.OriginXP)
				Else If CtrlObj.HasProp("OriginX") and !CtrlObj.HasProp("OriginXP")
					OriginX := CtrlObj.OriginX
				Else If !CtrlObj.HasProp("OriginX") and CtrlObj.HasProp("OriginXP")
					OriginX := CtrlW * CtrlObj.OriginXP
				Else
					OriginX := 0
				;}
				;{ OriginY
				If CtrlObj.HasProp("OriginY") and CtrlObj.HasProp("OriginYP")
					OriginY := CtrlObj.OriginY + (CtrlH * CtrlObj.OriginYP)
				Else If CtrlObj.HasProp("OriginY") and !CtrlObj.HasProp("OriginYP")
					OriginY := CtrlObj.OriginY
				Else If !CtrlObj.HasProp("OriginY") and CtrlObj.HasProp("OriginYP")
					OriginY := CtrlH * CtrlObj.OriginYP
				Else
					OriginY := 0
				;}
				;{ X
				If CtrlObj.HasProp("X") and CtrlObj.HasProp("XP")
					CtrlX := Mod(LimitX + CtrlObj.X + (AnchorW * CtrlObj.XP) - OriginX, LimitX)
				Else If CtrlObj.HasProp("X") and !CtrlObj.HasProp("XP")
					CtrlX := Mod(LimitX + CtrlObj.X - OriginX, LimitX)
				Else If !CtrlObj.HasProp("X") and CtrlObj.HasProp("XP")
					CtrlX := Mod(LimitX + (AnchorW * CtrlObj.XP) - OriginX, LimitX)
				;}
				;{ Y
				If CtrlObj.HasProp("Y") and CtrlObj.HasProp("YP")
					CtrlY := Mod(LimitY + CtrlObj.Y + (AnchorH * CtrlObj.YP) - OriginY, LimitY)
				Else If CtrlObj.HasProp("Y") and !CtrlObj.HasProp("YP")
					CtrlY := Mod(LimitY + CtrlObj.Y - OriginY, LimitY)
				Else If !CtrlObj.HasProp("Y") and CtrlObj.HasProp("YP")
					CtrlY := Mod(LimitY + AnchorH * CtrlObj.YP - OriginY, LimitY)
				;}
				;{ Width
				If CtrlObj.HasProp("Width") and CtrlObj.HasProp("WidthP")
					(CtrlObj.Width > 0 and CtrlObj.WidthP > 0 ? CtrlW := CtrlObj.Width + AnchorW * CtrlObj.WidthP : CtrlW := CtrlObj.Width + AnchorW + AnchorW * CtrlObj.WidthP - CtrlX)
				Else If CtrlObj.HasProp("Width") and !CtrlObj.HasProp("WidthP")
					(CtrlObj.Width > 0 ? CtrlW := CtrlObj.Width : CtrlW := AnchorW + CtrlObj.Width - CtrlX)
				Else If !CtrlObj.HasProp("Width") and CtrlObj.HasProp("WidthP")
					(CtrlObj.WidthP > 0 ? CtrlW := AnchorW * CtrlObj.WidthP : CtrlW := AnchorW + AnchorW * CtrlObj.WidthP - CtrlX)
				;}
				;{ Height
				If CtrlObj.HasProp("Height") and CtrlObj.HasProp("HeightP")
					(CtrlObj.Height > 0 and CtrlObj.HeightP > 0 ? CtrlH := CtrlObj.Height + AnchorH * CtrlObj.HeightP : CtrlH := CtrlObj.Height + AnchorH + AnchorH * CtrlObj.HeightP - CtrlY)
				Else If CtrlObj.HasProp("Height") and !CtrlObj.HasProp("HeightP")
					(CtrlObj.Height > 0 ? CtrlH := CtrlObj.Height : CtrlH := AnchorH + CtrlObj.Height - CtrlY)
				Else If !CtrlObj.HasProp("Height") and CtrlObj.HasProp("HeightP")
					(CtrlObj.HeightP > 0 ? CtrlH := AnchorH * CtrlObj.HeightP : CtrlH := AnchorH + AnchorH * CtrlObj.HeightP - CtrlY)
				;}
				;{ Min Max
				(CtrlObj.HasProp("MinX") ? MinX := CtrlObj.MinX : MinX := -999999)
				(CtrlObj.HasProp("MaxX") ? MaxX := CtrlObj.MaxX : MaxX := 999999)
				(CtrlObj.HasProp("MinY") ? MinY := CtrlObj.MinY : MinY := -999999)
				(CtrlObj.HasProp("MaxY") ? MaxY := CtrlObj.MaxY : MaxY := 999999)
				(CtrlObj.HasProp("MinWidth") ? MinW := CtrlObj.MinWidth : MinW := 0)
				(CtrlObj.HasProp("MaxWidth") ? MaxW := CtrlObj.MaxWidth : MaxW := 999999)
				(CtrlObj.HasProp("MinHeight") ? MinH := CtrlObj.MinHeight : MinH := 0)
				(CtrlObj.HasProp("MaxHeight") ? MaxH := CtrlObj.MaxHeight : MaxH := 999999)
				CtrlX := MinMax(CtrlX, MinX, MaxX)
				CtrlY := MinMax(CtrlY, MinY, MaxY)
				CtrlW := MinMax(CtrlW, MinW, MaxW)
				CtrlH := MinMax(CtrlH, MinH, MaxH)
				;}
				;{ Move and Size
				CtrlObj.Move(CtrlX + OffsetX, CtrlY + OffsetY, CtrlW, CtrlH)
				;}
				;{ Redraw on Cleanup or GuiObj.Init
				If GuiObj.Init or (CtrlObj.HasProp("Cleanup") and CtrlObj.Cleanup = true)
					CtrlObj.Redraw()
				;}
				;{ Custom Function Call
				If CtrlObj.HasProp("Function")
					CtrlObj.Function(GuiObj) ; CtrlObj is hidden 'this' first parameter
				;}
			}
			If !IsSet(Repeat) ; Break loop if no Repeat is needed because of Anchor or Maximize
				Break
		}
		;}
		;{ Reduce GuiObj.Init Counter and Check for Call again
		If (GuiObj.Init := GuiObj.Init - 1 > 0) {
			GuiObj.GetClientPos(, , &AnchorW, &AnchorH)
			GuiReSizer(GuiObj, WindowMinMax, AnchorW, AnchorH)
		}
		If WindowMinMax = 1 ; maximized
			GuiObj.Init := 2 ; redraw twice on next call after a maximize
		;}
		;{ Functions: Helpers
		MinMax(Num, MinNum, MaxNum) => Min(Max(Num, MinNum), MaxNum)
		;}
	}
	;}
	
	;{ Methods:
	;{ Options
	; Static Opt(CtrlObj, Options) => GuiReSizer.Options(CtrlObj, Options)
	Static Opt(CtrlObj, Options) => GuiReSizer2.Options(CtrlObj, Options)
	
	Static Options(CtrlObj, Options) {
		For Option in StrSplit(Options, " ") {
			For Abbr, Cmd in Map(
				"xp", "XP", "yp", "YP", "x", "X", "y", "Y",
				"wp", "WidthP", "hp", "HeightP", "w", "Width", "h", "Height",
				"minx", "MinX", "maxx", "MaxX", "miny", "MinY", "maxy", "MaxY", 
				"minw", "MinWidth", "maxw", "MaxWidth", "minh", "MinHeight", "maxh", "MaxHeight",
				"oxp", "OriginXP", "oyp", "OriginYP", "ox", "OriginX", "oy", "OriginY") {
				If RegExMatch(Option, "i)^" Abbr "([\d.-]*$)", &Match) {
					CtrlObj.%Cmd% := Match.1
					Break
				}
			}
			; Origin letters
			If SubStr(Option, 1, 1) = "o" {
				Flags := SubStr(Option, 2)
				If Flags ~= "i)l"           ; left
					CtrlObj.OriginXP := 0
				If Flags ~= "i)c"           ; center (left to right)
					CtrlObj.OriginXP := 0.5
				If Flags ~= "i)r"           ; right
					CtrlObj.OriginXP := 1
				If Flags ~= "i)t"           ; top
					CtrlObj.OriginYP := 0
				If Flags ~= "i)m"           ; middle (top to bottom)
					CtrlObj.OriginYP := 0.5
				If Flags ~= "i)b"           ; bottom
					CtrlObj.OriginYP := 1
			}
		}
	}
	;}
	;{ Now
	Static Now(GuiObj, Redraw := true, Init := 2) {
		If Redraw
			GuiObj.Init := Init
		GuiObj.GetClientPos(, , &Width, &Height)
		GuiReSizer(GuiObj, WindowMinMax := 1, Width, Height)
	}
}
/*
    Github: https://github.com/Nich-Cebolla/AutoHotkey-LibV2/blob/main/FillStr.ahk
    Author: Nich-Cebolla
    Version: 1.0.0
    License: MIT
*/

/**
 * @class
 * In this documentation an instance of `FillStr` is referred to as `Filler`.
 * FillStr constructs strings of the requested length out of the provided filler string. Multiple
 * `Filler` objects can be active at any time. It would technically be possible to use a single
 * `Filler` object and swap out the substrings on the property `Filler.Str`, but this is not
 * recommended because FillStr caches some substrings for efficiency, so you may not get the expected
 * result after swapping out the `Str` property.
 *
 * Internally, FillStr works by deconstructing the input integer into its base 10 components. It
 * constructs then caches the strings for components that are divisible by 10, then adds on the
 * remainder. This offers a balance between efficiency, flexibility, and memory usage.
 *
 * Since this is expected to be most frequently used to pad strings with surrounding whitespace,
 * the `FillStr` object is instantiated with an instance of itself using a single space character
 * as the filler string. This is available on the property `FillStr.S`, and can also be utilized using
 * `FillStr[Qty]` to output a string of Qty space characters.
 */
class FillStr {
    static __New() {
        this.S := FillStr(' ')
    }
    static __Item[Qty] {
        Get => this.S[Qty]
        Set => this.S.Cache.Set(Qty, value)
    }

    /**
     * @description - Constructs the offset string according to the input parameters.
     * @param {Integer} Len - The length of the output string.
     * @param {Integer} TruncateAction - Controls how the filler string `Filler.Str` is truncated when
     * `Len` is not evenly divisible by `Filler.Len`. The options are:
     * - 0: Does not truncate the filler string, and allows the width of the output string to exceed
     * `Len`.
     * - 1: Does not truncate the filler string, and does not allow the width of the output string to
     * exceed `Len`, sometimes resulting in the width being less than `Len`.
     * - 2: Does not truncate the filler string, and does not allow the width of the output string to
     * exceed `Len`, and adds space characters to fill the remaining space. The space characters are
     * added to the left side of the output string.
     * - 3: Does not truncate the filler string, and does not allow the width of the output string to
     * exceed `Len`, and adds space characters to fill the remaining space. The space characters are
     * added to the right side of the output string.
     * - 4: Truncates the filler string, and the truncated portion is on the left side of the output
     * string.
     * - 5: Truncates the filler string, and the truncated portion is on the right side of the output
     * string.
     */
    static GetOffsetStr(Len, TruncateAction, self) {
        Out := self[Floor(Len / self.Len)]
        if R := Mod(Len, self.Len) {
            switch TruncateAction {
                case 0: Out .= self[1]
                case 2: Out := FillStr[R] Out
                case 3: Out .= FillStr[R]
                case 4: Out := SubStr(self[1], self.Len - R + 1) Out
                case 5: Out .= SubStr(self[1], 1, R)
            }
        }
        return Out
    }

    /**
     * @description - Creates a new FillStr object, referred to as `Filler` in this documentation.
     * Use the FillStr instance to generate strings of repeating characters. For general usage,
     * see {@link FillStr#__Item}.
     * @param {String} Str - The string to repeat.
     * @example
        Filler := FillStr('-')
        Filler[10] ; ----------
        Filler.LeftAlign('Hello, world!', 26)       ; Hello, world!-------------
        Filler.LeftAlign('Hello, world!', 26, 5)    ; -----Hello, world!--------
        Filler.CenterAlign('Hello, world!', 26)     ; -------Hello, world!------
        Filler.CenterAlign('Hello, world!', 26, 1)  ; -------Hello, world!------
        Filler.CenterAlign('Hello, world!', 26, 2)  ; ------Hello, world!-------
        Filler.CenterAlign('Hello, world!', 26, 3)  ; -------Hello, world!-------
        Filler.CenterAlign('Hello, world!', 26, 4)  ; ------Hello, world!------
        Filler.RightAlign('Hello, world!', 26)      ; -------------Hello, world!
        Filler.RightAlign('Hello, world!', 26, 5)   ; --------Hello, world!-----
     * @
     * @returns {FillStr} - A new FillStr object.
     */
    __New(Str) {
        this.Str := Str
        Loop 10
            Out .= Str
        this[10] := Out
        this.Len := StrLen(Str)
    }
    Cache := Map()
    __Item[Qty] {
        /**
         * @description - Returns the string of the specified number of repetitions. The `Qty`
         * parameter does not represent string length, it represents number of repetitions of
         * `Filler.Str`, which is the same as string length only when the length of `Filler.Str` == 1.
         * @param {Integer} Qty - The number of repetitions.
         * @returns {String} - The string of the specified number of repetitions.
         */
        Get {
            if !Qty
                return ''
            Out := ''
            if this.Cache.Has(Number(Qty))
                return this.Cache[Number(Qty)]
            r := Mod(Qty, 10)
            Loop r
                Out .= this.Str
            Qty -= r
            if Qty {
                Split := StrSplit(Qty)
                for n in Split {
                    if n = 0
                        continue
                    Tens := 1
                    Loop StrLen(Qty) - A_Index
                        Tens := Tens * 10
                    if this.Cache.Has(Tens) {
                        Loop n
                            Out .= this.Cache.Get(Tens)
                    } else {
                        Loop n
                            Out .= _Process(Tens)
                    }
                }
            }
            return Out

            _Process(Qty) {
                local Out
                ; if !RegExMatch(Qty, '^10+$')
                ;     throw Error('Logical error in _Process function call.', -1)
                Tenth := Integer(Qty / 10)
                if this.Cache.Has(Tenth) {
                    Loop 10
                        Out .= this.Cache.Get(Tenth)
                } else
                    Out := _Process(Tenth)
                this.Cache.Set(Number(Qty), Out)
                return Out
            }
        }
        /**
         * @description - Sets the cache value of the indicated `Qty`. This can be useful in a
         * situation where you know you will be using a string of X length often, but X is not
         * divisible by 10. `FillStr` instances do not cache lengths unless they are divisible by
         * 10 to avoid memory bloat, but will still return a cached value if the input Qty exists in
         * the cache.
         */
        Set {
            this.Cache.Set(Number(Qty), value)
        }
    }

    /**
     * @description - Center aligns the string within a specified width. This method is compatible
     * with filler strings of any length.
     * @param {String} Str - The string to center align.
     * @param {Integer} Width - The width of the output string in number of characters.
     * @param {Number} [RemainderAction=1] - The action to take when the difference between the width
     * and the string length is not evenly divisible by 2.
     * - 0: Exclude the remainder.
     * - 1: Add the remainder to the left side.
     * - 2: Add the remainder to the right side.
     * - 3: Add the remainder to both sides.
     */
    CenterAlign(Str, Width, RemainderAction := 1, Padding := ' ', TruncateActionLeft := 1, TruncateActionRight := 2) {
        Space := Width - StrLen(Str) - (LenPadding := StrLen(Padding) * 2)
        if Space < 1
            return Str
        Split := Floor(Space / 2)
        if R := Mod(Space, 2) {
            switch RemainderAction {
                case 0: LeftOffset := RightOffset := Split
                case 1: LeftOffset := Split + R, RightOffset := Split
                case 2: LeftOffset := Split, RightOffset := Split + R
                case 3: LeftOffset := RightOffset := Split + R
                default:
                    throw MethodError('Invalid RemainderAction.', -1, 'RemainderAction: ' RemainderAction)
            }
        } else
            LeftOffset := RightOffset := Split
        return FillStr.GetOffsetStr(LeftOffset, TruncateActionLeft, this) Padding Str Padding FillStr.GetOffsetStr(RightOffset, TruncateActionRight, this)
    }

    /**
     * @description - Center aligns a string within a specified width. This method is only compatible
     * with filler strings that are 1 character in length.
     * @param {String} Str - The string to center align.
     * @param {Number} Width - The width of the output string.
     * @param {Number} [RemainderAction=1] - The action to take when the difference between the width
     * and the string length is not evenly divisible by 2.
     * - 0: Exclude the remainder.
     * - 1: Add the remainder to the left side.
     * - 2: Add the remainder to the right side.
     * - 3: Add the remainder to both sides.
     * @returns {String} - The center aligned string.
     */
    CenterAlignA(Str, Width, RemainderAction := 1) {
        Space := Width - StrLen(Str)
        r := Mod(Space, 2)
        Split := (Space - r) / 2
        switch RemainderAction {
            case 0: return this[Split] Str this[Split]
            case 1: return this[Split + r] Str this[Split]
            case 2: return this[Split] Str this[Split + r]
            case 3: return this[Split + r] Str this[Split + r]
            default:
                throw MethodError('Invalid RemainderAction.', -1, 'RemainderAction: ' RemainderAction)
        }
    }

    /** @description - Clears the cache. */
    ClearCache() => this.Cache.Clear()

    /**
     * @description - Left aligns a string within a specified width. This method is compatible with
     * filler strings of any length.
     * @param {String} Str - The string to left align.
     * @param {Integer} Width - The width of the output string in number of characters.
     * @param {Integer} [LeftOffset=0] - The offset from the left side in number of characters. The
     * offset is constructed by using the filler string (`Filler.Str`) value and repeating
     * it until the offset length is reached.
     * @param {String} [Padding=' '] - The `Padding` value is added to the left and right side of
     * `Str` to create space between the string and the filler characters. To not use padding, set
     * it to an empty string.
     * @param {Integer} [TruncateActionLeft=1] - This parameter controls how the filler string
     * `Filler.Str` is truncated when the LeftOffset is not evenly divisible by the length of
     * `Filler.Str`. For a full explanation, see {@link FillStr.GetOffsetStr}.
     * @param {Integer} [TruncateActionRight=2] - This parameter controls how the filler string
     * `Filler.Str` is truncated when the remaining character count on the right side of the output
     * string is not evenly divisible by the length of `Filler.Str`. For a full explanation, see
     * {@link FillStr.GetOffsetStr}.
     */
    LeftAlign(Str, Width, LeftOffset := 0, Padding := ' ', TruncateActionLeft := 1, TruncateActionRight := 2) {
        if LeftOffset + (LenStr := StrLen(Str)) + (LenPadding := StrLen(Padding) * 2) > Width
            LeftOffset := Width - LenStr - LenPadding
        if LeftOffset > 0
            Out .= FillStr.GetOffsetStr(LeftOffset, TruncateActionLeft, this)
        Out .= Padding Str Padding
        if (Remainder := Width - StrLen(Out))
            Out .= FillStr.GetOffsetStr(Remainder, TruncateActionRight, this)
        return Out
    }

    /**
     * @description - Left aligns a string within a specified width. This method is only compatible
     * with filler strings that are 1 character in length.
     * @param {String} Str - The string to left align.
     * @param {Number} Width - The width of the output string.
     * @param {Number} [LeftOffset=0] - The offset from the left side.
     * @returns {String} - The left aligned string.
     */
    LeftAlignA(Str, Width, LeftOffset := 0) {
        if LeftOffset {
            if LeftOffset + StrLen(Str) > Width
                LeftOffset := Width - StrLen(Str)
            return this[LeftOffset] Str this[Width - StrLen(Str) - LeftOffset]
        }
        return Str this[Width - StrLen(Str)]
    }

    ; /**
    ;  * @description - Right aligns a string within a specified width. This method is compatible with
    ;  * filler strings of any length.
    ;  * @param {String} Str - The string to right align.
    ;  * @param {Integer} Width - The width of the output string in number of characters.
    ;  * @param {Integer} [RightOffset=0] - The offset from the right side in number of characters. The
    ;  * offset is constructed by using the filler string (`Filler.Str`) value and repeating
    ;  * it until the offset length is reached.
    ;  * @param {String} [Padding=' '] - The `Padding` value is added to the left and right side of
    ;  * `Str` to create space between the string and the filler characters. To not use padding, set
    ;  * it to an empty string.
    ;  * @param {Integer} [TruncateActionLeft=1] - This parameter controls how the filler string
    ;  * `Filler.Str` is truncated when the remaining character count on the left side of the output
    ;  * string is not evenly divisible by the length of `Filler.Str`. For a full explanation, see
    ;  * {@link FillStr.GetOffsetStr}.
    ;  * @param {Integer} [TruncateActionRight=2] - This parameter controls how the filler string
    ;  * `Filler.Str` is truncated when the RightOffset is not evenly divisible by the length of
    ;  * `Filler.Str`. For a full explanation, see {@link FillStr.GetOffsetStr}.
    ;  * @returns {String} - The right aligned string.
    ;  */
    ; RightAlign(Str, Width, RightOffset := 0, Padding := ' ', TruncateActionLeft := 1, TruncateActionRight := 2) {
    ;     if RightOffset + (LenStr := StrLen(Str)) + (LenPadding := StrLen(Padding) * 2) > Width
    ;         RightOffset := Width - LenStr - LenPadding
    ;     Out := Padding Str Padding
    ;     if (Remainder := Width - StrLen(Out) - RightOffset)
    ;         Out := FillStr.GetOffsetStr(Remainder, TruncateActionRight, this) Out
    ;     if RightOffset > 0
    ;         Out := FillStr.GetOffsetStr(RightOffset, TruncateActionLeft, this) Out
    ;     return Out
    ; }

	/**
	 * Right aligns text within a specified width with flexible padding and offset options
	 * @param {String} params* - Parameters in flexible order:
	 *   - str: String to align
	 *   - width: Total width for alignment 
	 *   - rightOffset: Offset from right edge (default: 0)
	 *   - padding: Padding character/string (default: ' ')
	 *   - truncateActionLeft: Left truncation mode (default: 1)
	 *   - truncateActionRight: Right truncation mode (default: 2)
	 * @returns {String} Right-aligned text string
	 * @throws {ValueError} If width < string length
	 */
	RightAlign(params*) {
		; Initialize defaults
		config := {
			str: "",
			width: 0, 
			rightOffset: 0,
			padding: " ",
			truncateActionLeft: 1,
			truncateActionRight: 2
		}
	
		; Parse parameters
		for param in params {
			if (param is String && !config.str)
				config.str := param
			else if (param is Integer && !config.width)
				config.width := param
			else if (param is Integer)
				config.rightOffset := param
			else if (param is String)
				config.padding := param
		}
	
		; Validate
		if (!config.str || !config.width)
			throw ValueError("String and width are required", -1)
			
		if (config.rightOffset + (lenStr := StrLen(config.str)) + 
			(lenPadding := StrLen(config.padding) * 2) > config.width)
			config.rightOffset := config.width - lenStr - lenPadding
	
		; Build output
		out := config.padding config.str config.padding
		
		if (remainder := config.width - StrLen(out) - config.rightOffset)
			out := FillStr.GetOffsetStr(remainder, config.truncateActionRight, this) out
			
		if (config.rightOffset > 0)
			out := FillStr.GetOffsetStr(config.rightOffset, config.truncateActionLeft, this) out
	
		return out
	}
    /**
     * @description - Right aligns a string within a specified width. This method is only compatible
     * with filler strings that are 1 character in length.
     * @param {String} Str - The string to right align.
     * @param {Number} Width - The width of the output string.
     * @param {Number} [RightOffset=0] - The offset from the right side.
     * @returns {String} - The right aligned string.
     */
    RightAlignA(Str, Width, RightOffset := 0) {
        if RightOffset {
            if RightOffset + StrLen(Str) > Width
                RightOffset := Width - StrLen(Str)
            return this[Width - StrLen(Str) - RightOffset] Str this[RightOffset]
        }
        return this[Width - StrLen(Str)] Str
    }
}

/*
    Github: https://github.com/Nich-Cebolla/AutoHotkey-LibV2/blob/main/Align.ahk
    Author: Nich-Cebolla
    Version: 1.0.0
    License: MIT
*/

class Align {
    static DPI_AWARENESS_CONTEXT := -4

    /**
     * @description - Centers the Subject window horizontally with respect to the Target window.
     * @param {Gui|Gui.Control|Align} Subject - The window to be centered.
     * @param {Gui|Gui.Control|Align} Target - The reference window.
     */
    static CenterH(Subject, Target) {
        Subject.GetPos(&X1, &Y1, &W1)
        Target.GetPos(&X2, , &W2)
        Subject.Move(X2 + W2 / 2 - W1 / 2, Y1)
    }

    /**
     * @description - Centers the two windows horizontally with one another, splitting the difference
     * between them.
     * @param {Gui|Gui.Control|Align} Win1 - The first window to be centered.
     * @param {Gui|Gui.Control|Align} Win2 - The second window to be centered.
     */
    static CenterHSplit(Win1, Win2) {
        Win1.GetPos(&X1, &Y1, &W1)
        Win2.GetPos(&X2, &Y2, &W2)
        diff := X1 + 0.5 * W1 - X2 - 0.5 * W2
        X1 -= diff * 0.5
        X2 += diff * 0.5
        Win1.Move(X1, Y1)
        Win2.Move(X2, Y2)
    }

    /**
     * @description - Centers the Subject window vertically with respect to the Target window.
     * @param {Gui|Gui.Control|Align} Subject - The window to be centered.
     * @param {Gui|Gui.Control|Align} Target - The reference window.
     */
    static CenterV(Subject, Target) {
        Subject.GetPos(&X1, &Y1, , &H1)
        Target.GetPos( , &Y2, , &H2)
        Subject.Move(X1, Y2 + H2 / 2 - H1 / 2)
    }

    /**
     * @description - Centers the two windows vertically with one another, splitting the difference
     * between them.
     * @param {Gui|Gui.Control|Align} Win1 - The first window to be centered.
     * @param {Gui|Gui.Control|Align} Win2 - The second window to be centered.
     */
    static CenterVSplit(Win1, Win2) {
        Win1.GetPos(&X1, &Y1, , &H1)
        Win2.GetPos(&X2, &Y2, , &H2)
        diff := Y1 + 0.5 * H1 - Y2 - 0.5 * H2
        Y1 -= diff * 0.5
        Y2 += diff * 0.5
        Win1.Move(X1, Y1)
        Win2.Move(X2, Y2)
    }

    /**
     * @description - Centers a list of windows horizontally with respect to one another, splitting
     * the difference between them. The center of each window will be the midpoint between the least
     * and greatest X coordinates of the windows.
     * @param {Array} List - An array of windows to be centered. This function assumes there are
     * no unset indices.
     */
    static CenterHList(List) {
        if !(hDwp := DllCall('BeginDeferWindowPos', 'int', List.Length, 'ptr')) {
            throw Error('``BeginDeferWindowPos`` failed.', -1)
        }
        List[-1].GetPos(&L, &Y, &W)
        Params := [{ Y: Y, M: W / 2, Hwnd: List[-1].Hwnd }]
        Params.Capacity := List.Length
        R := L + W
        loop List.Length - 1 {
            List[A_Index].GetPos(&X, &Y, &W)
            Params.Push({ Y: Y, M: W / 2, Hwnd: List[A_Index].Hwnd })
            if X < L
                L := X
            if X + W > R
                R := X + W
        }
        Center := (R - L) / 2 + L
        for ps in Params {
            if !(hDwp := DllCall('DeferWindowPos'
                , 'ptr', hDwp
                , 'ptr', ps.Hwnd
                , 'ptr', 0
                , 'int', Center - ps.M
                , 'int', ps.Y
                , 'int', 0
                , 'int', 0
                , 'uint', 0x0001 | 0x0004 | 0x0010 ; SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE
                , 'ptr'
            )) {
                throw Error('``DeferWindowPos`` failed.', -1)
            }
        }
        if !DllCall('EndDeferWindowPos', 'ptr', hDwp, 'ptr') {
            throw Error('``EndDeferWindowPos`` failed.', -1)
        }
        return
    }

    /**
     * @description - Centers a list of windows vertically with respect to one another, splitting
     * the difference between them. The center of each window will be the midpoint between the least
     * and greatest Y coordinates of the windows.
     * @param {Array} List - An array of windows to be centered. This function assumes there are
     * no unset indices.
     */
    static CenterVList(List) {
        if !(hDwp := DllCall('BeginDeferWindowPos', 'int', List.Length, 'ptr')) {
            throw Error('``BeginDeferWindowPos`` failed.', -1)
        }
        List[-1].GetPos(&X, &T, , &H)
        Params := [{ X: X, M: H / 2, Hwnd: List[-1].Hwnd }]
        Params.Capacity := List.Length
        B := T + H
        loop List.Length - 1 {
            List[A_Index].GetPos(&X, &Y, , &H)
            Params.Push({ X: X, M: H / 2, Hwnd: List[A_Index].Hwnd })
            if Y < T
                T := Y
            if Y + H > B
                B := Y + H
        }
        Center := (B - T) / 2 + T
        for ps in Params {
            if !(hDwp := DllCall('DeferWindowPos'
                , 'ptr', hDwp
                , 'ptr', ps.Hwnd
                , 'ptr', 0
                , 'int', ps.X
                , 'int', Center - ps.M
                , 'int', 0
                , 'int', 0
                , 'uint', 0x0001 | 0x0004 | 0x0010 ; SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE
                , 'ptr'
            )) {
                throw Error('``DeferWindowPos`` failed.', -1)
            }
        }
        if !DllCall('EndDeferWindowPos', 'ptr', hDwp, 'ptr') {
            throw Error('``EndDeferWindowPos`` failed.', -1)
        }
        return
    }

    /**
     * @description - Standardizes a group's width to the largest width in the group.
     * @param {Array} List - An array of windows to be standardized. This function assumes there are
     * no unset indices.
     */
    static GroupWidth(List) {
        if !(hDwp := DllCall('BeginDeferWindowPos', 'int', List.Length, 'ptr')) {
            throw Error('``BeginDeferWindowPos`` failed.', -1)
        }
        List[-1].GetPos(, , &GW, &H)
        Params := [{ H: H, Hwnd: List[-1].Hwnd }]
        Params.Capacity := List.Length
        loop List.Length - 1 {
            List[A_Index].GetPos(, , &W, &H)
            Params.Push({ H: H, Hwnd: List[A_Index].Hwnd })
            if W > GW
                GW := W
        }
        for ps in Params {
            if !(hDwp := DllCall('DeferWindowPos'
                , 'ptr', hDwp
                , 'ptr', ps.Hwnd
                , 'ptr', 0
                , 'int', 0
                , 'int', 0
                , 'int', GW
                , 'int', ps.H
                , 'uint', 0x0002 | 0x0004 | 0x0010 ; SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE
                , 'ptr'
            )) {
                throw Error('``DeferWindowPos`` failed.', -1)
            }
        }
        if !DllCall('EndDeferWindowPos', 'ptr', hDwp, 'ptr') {
            throw Error('``EndDeferWindowPos`` failed.', -1)
        }
        return
    }

    static GroupWidthCb(G, Callback, ApproxCount := 2) {
        if !(hDwp := DllCall('BeginDeferWindowPos', 'int', ApproxCount, 'ptr')) {
            throw Error('``BeginDeferWindowPos`` failed.', -1)
        }
        GW := -99999
        Params := []
        Params.Capacity := ApproxCount
        for Ctrl in G {
            Ctrl.GetPos(, , &W, &H)
            if Callback(&GW, W, Ctrl) {
                Params.Push({ H: H, Hwnd: Ctrl.Hwnd })
                break
            }
        }
        for ps in Params {
            if !(hDwp := DllCall('DeferWindowPos'
                , 'ptr', hDwp
                , 'ptr', ps.Hwnd
                , 'ptr', 0
                , 'int', 0
                , 'int', 0
                , 'int', GW
                , 'int', ps.H
                , 'uint', 0x0002 | 0x0004 | 0x0010 ; SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE
                , 'ptr'
            )) {
                throw Error('``DeferWindowPos`` failed.', -1)
            }
        }
        if !DllCall('EndDeferWindowPos', 'ptr', hDwp, 'ptr') {
            throw Error('``EndDeferWindowPos`` failed.', -1)
        }
        return
    }

    /**
     * @description - Standardizes a group's height to the largest height in the group.
     * @param {Array} List - An array of windows to be standardized. This function assumes there are
     * no unset indices.
     */
    static GroupHeight(List) {
        if !(hDwp := DllCall('BeginDeferWindowPos', 'int', List.Length, 'ptr')) {
            throw Error('``BeginDeferWindowPos`` failed.', -1)
        }
        List[-1].GetPos(, , &W, &GH)
        Params := [{ W: W, Hwnd: List[-1].Hwnd }]
        Params.Capacity := List.Length
        loop List.Length - 1 {
            List[A_Index].GetPos(, , &W, &H)
            Params.Push({ W: W, Hwnd: List[A_Index].Hwnd })
            if H > GH
                GH := H
        }
        for ps in Params {
            if !(hDwp := DllCall('DeferWindowPos'
                , 'ptr', hDwp
                , 'ptr', ps.Hwnd
                , 'ptr', 0
                , 'int', 0
                , 'int', 0
                , 'int', ps.W
                , 'int', GH
                , 'uint', 0x0002 | 0x0004 | 0x0010 ; SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE
                , 'ptr'
            )) {
                throw Error('``DeferWindowPos`` failed.', -1)
            }
        }
        if !DllCall('EndDeferWindowPos', 'ptr', hDwp, 'ptr') {
            throw Error('``EndDeferWindowPos`` failed.', -1)
        }
        return
    }

    static GroupHeightCb(G, Callback, ApproxCount := 2) {
        if !(hDwp := DllCall('BeginDeferWindowPos', 'int', ApproxCount, 'ptr')) {
            throw Error('``BeginDeferWindowPos`` failed.', -1)
        }
        GH := -99999
        Params := []
        Params.Capacity := ApproxCount
        for Ctrl in G {
            Ctrl.GetPos(, , &W, &H)
            if Callback(&GH, H, Ctrl) {
                Params.Push({ W: W, Hwnd: Ctrl.Hwnd })
                break
            }
        }
        for ps in Params {
            if !(hDwp := DllCall('DeferWindowPos'
                , 'ptr', hDwp
                , 'ptr', ps.Hwnd
                , 'ptr', 0
                , 'int', 0
                , 'int', 0
                , 'int', ps.W
                , 'int', GH
                , 'uint', 0x0002 | 0x0004 | 0x0010 ; SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE
                , 'ptr'
            )) {
                throw Error('``DeferWindowPos`` failed.', -1)
            }
        }
        if !DllCall('EndDeferWindowPos', 'ptr', hDwp, 'ptr') {
            throw Error('``EndDeferWindowPos`` failed.', -1)
        }
        return
    }

    /**
     * @description - Allows the usage of the `_S` suffix for each function call. When you include
     * `_S` at the end of any function call, the function will call `SetThreadDpiAwarenessContext`
     * prior to executing the function. The value used will be `Align.DPI_AWARENESS_CONTEXT`, which
     * is initialized at `-4`, but you can change it to any value.
     * @example
        Align.DPI_AWARENESS_CONTEXT := -5
     * @
     */
    static __Call(Name, Params) {
        Split := StrSplit(Name, '_')
        if this.HasMethod(Split[1]) && Split[2] = 'S' {
            DllCall('SetThreadDpiAwarenessContext', 'ptr', this.DPI_AWARENESS_CONTEXT, 'ptr')
            if Params.Length {
                return this.%Split[1]%(Params*)
            } else {
                return this.%Split[1]%()
            }
        } else {
            throw PropertyError('Property not found.', -1, Name)
        }
    }

    /**
     * @description - Creates a proxy for non-AHK windows.
     * @param {HWND} Hwnd - The handle of the window to be proxied.
     */
    __New(Hwnd) {
        this.Hwnd := Hwnd
    }
	; 
    GetPos(&X?, &Y?, &W?, &H?) {
        WinGetPos(&X, &Y, &W, &H, this.Hwnd)
    }
	/**
	 * @description - Moves the window to the specified position and size.
	 * @param {Number} [X] - The new X coordinate of the window.
	 * @param {Number} [Y] - The new Y coordinate of the window.
	 * @param {Number} [W] - The new width of the window.
	 * @param {Number} [H] - The new height of the window.
	 */
    Move(X?, Y?, W?, H?) {
        WinMove(X ?? unset, Y ?? unset, W ?? unset, H ?? unset, this.Hwnd)
    }
}

/**
	* Enhanced message box with rich text support using Gui2.AddRichEdit
	*/
/**
	* Enhanced message box with rich text support using Gui2.AddRichEdit
	*/
class RTFMsgBox {
	static Instances := Map()
	static InstanceCount := 0  ; Add counter for debugging
	
	; Default settings
	DefaultSettings := {
		Width: 400,
		MinHeight: 150,
		MaxHeight: 600,
		ButtonHeight: 30,
		MarginX: 20,
		MarginY: 15,
		Font: {
			Name: "Segoe UI",
			Size: 10
		},
		Colors: {
			Background: 0xFFFFFF,
			Text: 0x000000,
			Button: 0xF0F0F0
		}
	}

	; static rtfgui := this.rtfgui

	__New(text, title := "", options := "", owner := "") {

		; Debug output
		RTFMsgBox.InstanceCount += 1

		OutputDebug("RTFMsgBox instance created. Count: " RTFMsgBox.InstanceCount "`n")
		OutputDebug("Call stack: `n" debug_getCallStack() "`n")

		MB_TYPES := Map(
			"OK", ["OK"],
			"OKCancel", ["OK", "Cancel"],
			"YesNo", ["Yes", "No"],
			"YesNoCancel", ["Yes", "No", "Cancel"],
			"RetryCancel", ["Retry", "Cancel"],
			"AbortRetryIgnore", ["Abort", "Retry", "Ignore"]
		)

		; Create GUI
		title := (title ? title : "RTFMsgBox_" RTFMsgBox.InstanceCount)
		this.rtfGui := Gui("+Owner" (owner ? owner : "") " +AlwaysOnTop -MinimizeBox")
		this.rtfGui.Title := title
		this.rtfGui.BackColor := this.DefaultSettings.Colors.Background
		this.rtfGui.SetFont("s" this.DefaultSettings.Font.Size, this.DefaultSettings.Font.Name)

		; Parse options
		buttons := MB_TYPES["OK"]  ; Default buttons
		for type, btnSet in MB_TYPES {
			if InStr(options, type) {
				buttons := btnSet
				break
			}
		}

		; Calculate dimensions
		margin := this.DefaultSettings.MarginX
		width := this.DefaultSettings.Width
		editWidth := width - 2*margin

		; Add RichEdit using the enhanced method
		reOptions := Format("x{1} y{2} w{3} h{4}", 
			margin,
			margin,
			editWidth,
			this.DefaultSettings.MinHeight
		)
		
		this.RE := this.rtfGui.AddRichEdit(,reOptions, text)
		this.RE.ReadOnly := true

		; Calculate heights
		textHeight := min(max(10, this.DefaultSettings.MinHeight), this.DefaultSettings.MaxHeight)

		; Add buttons
		buttonY := textHeight + margin
		buttonWidth := (width - (buttons.Length + 1)*margin) / buttons.Length
		
		for i, buttonText in buttons {
			x := margin + (i-1)*(buttonWidth + margin)
			btn := this.rtfGui.AddButton(Format("x{1} y{2} w{3} h{4}",
				x, buttonY, buttonWidth, this.DefaultSettings.ButtonHeight),
				buttonText)
			btn.OnEvent("Click", this.ButtonClick.Bind(this))
		}

		; Set up result storage
		this.Result := ""

		; Calculate final height
		height := buttonY + this.DefaultSettings.ButtonHeight + margin

		; Set window title
		this.rtfGui.Title := title

		; ; Store instance
		; RTFMsgBox.Instances[this.rtfGui.Hwnd] := this
		
		; Store instance with the unique identifier
		RTFMsgBox.Instances[this.rtfGui.Hwnd] := {
			instance: this,
			createTime: A_TickCount
		}

		; Show the window and return immediately if we already have another instance waiting
		if (RTFMsgBox.InstanceCount > 1) {
			OutputDebug("Multiple RTFMsgBox instances detected - check for duplicate calls`n")
		}

		; Show the window
		this.rtfGui.Show(Format("w{1} h{2} Center", width, height))

		; Wait for result
		while !this.Result {
			Sleep(10)
		}

		return this.Result
		; return this
	}

	_Cleanup() {
		RTFMsgBox.InstanceCount--
		RTFMsgBox.Instances.Delete(this.rtfGui.Hwnd)
		OutputDebug("RTFMsgBox instance destroyed. Remaining count: " RTFMsgBox.InstanceCount "`n")
	}

	ButtonClick(GuiCtrl, *) {
		this.Result := GuiCtrl.Text
		this.rtfGui.Destroy()
	}

	static Show(text, title := "", options := "", owner := "") {
		return RTFMsgBox(text, title, options, owner)
	}
}

; Helper function to get call stack for debugging
debug_getCallStack() {
	stack := ""
	try {
		loop 10 {
			if (ex := Error("", -A_Index)) {
				stack .= Format("  Line {1}: {2}`n", ex.Line, ex.What)
			}
		}
	}
	return stack || "No call stack available`n"
}

; Helper function - modified to add debug info
MsgRTFBox(text, title := "", options := "YesNoCancel", owner := "") {
	Infos("MsgRTFBox called`n")
	return RTFMsgBox.Show(text, title, options, owner || A_ScriptHwnd)
}

class GuiColors {
	; Common named colors
	static mColors := Map(
		"aliceblue", "F0F8FF",
		"antiquewhite", "FAEBD7",
		"aqua", "00FFFF",
		"aquamarine", "7FFFD4",
		"azure", "F0FFFF",
		"beige", "F5F5DC",
		"bisque", "FFE4C4",
		"black", "000000",
		"blanchedalmond", "FFEBCD",
		"blue", "0000FF",
		"blueviolet", "8A2BE2",
		"brown", "A52A2A",
		"burlywood", "DEB887",
		"cadetblue", "5F9EA0",
		"chartreuse", "7FFF00",
		"chocolate", "D2691E",
		"coral", "FF7F50",
		"cornflowerblue", "6495ED",
		"cornsilk", "FFF8DC",
		"crimson", "DC143C",
		"cyan", "00FFFF",
		"darkblue", "00008B",
		"darkcyan", "008B8B",
		"darkgoldenrod", "B8860B",
		"darkgray", "A9A9A9",
		"darkgreen", "006400",
		"darkkhaki", "BDB76B",
		"darkmagenta", "8B008B",
		"darkolivegreen", "556B2F",
		"darkorange", "FF8C00",
		"darkorchid", "9932CC",
		"darkred", "8B0000",
		"darksalmon", "E9967A",
		"darkseagreen", "8FBC8F",
		"darkslateblue", "483D8B",
		"darkslategray", "2F4F4F",
		"darkturquoise", "00CED1",
		"darkviolet", "9400D3",
		"deeppink", "FF1493",
		"deepskyblue", "00BFFF",
		"dimgray", "696969",
		"dodgerblue", "1E90FF",
		"firebrick", "B22222",
		"floralwhite", "FFFAF0",
		"forestgreen", "228B22",
		"fuchsia", "FF00FF",
		"gainsboro", "DCDCDC",
		"ghostwhite", "F8F8FF",
		"gold", "FFD700",
		"goldenrod", "DAA520",
		"gray", "808080",
		"green", "008000",
		"greenyellow", "ADFF2F",
		"honeydew", "F0FFF0",
		"hotpink", "FF69B4",
		"indianred", "CD5C5C",
		"indigo", "4B0082",
		"ivory", "FFFFF0",
		"khaki", "F0E68C",
		"lavender", "E6E6FA",
		"lavenderblush", "FFF0F5",
		"lawngreen", "7CFC00",
		"lemonchiffon", "FFFACD",
		"lightblue", "ADD8E6",
		"lightcoral", "F08080",
		"lightcyan", "E0FFFF",
		"lightgoldenrodyellow", "FAFAD2",
		"lightgray", "D3D3D3",
		"lightgreen", "90EE90",
		"lightpink", "FFB6C1",
		"lightsalmon", "FFA07A",
		"lightseagreen", "20B2AA",
		"lightskyblue", "87CEFA",
		"lightslategray", "778899",
		"lightsteelblue", "B0C4DE",
		"lightyellow", "FFFFE0",
		"lime", "00FF00",
		"limegreen", "32CD32",
		"linen", "FAF0E6",
		"magenta", "FF00FF",
		"maroon", "800000",
		"mediumaquamarine", "66CDAA",
		"mediumblue", "0000CD",
		"mediumorchid", "BA55D3",
		"mediumpurple", "9370DB",
		"mediumseagreen", "3CB371",
		"mediumslateblue", "7B68EE",
		"mediumspringgreen", "00FA9A",
		"mediumturquoise", "48D1CC",
		"mediumvioletred", "C71585",
		"midnightblue", "191970",
		"mintcream", "F5FFFA",
		"mistyrose", "FFE4E1",
		"moccasin", "FFE4B5",
		"navajowhite", "FFDEAD",
		"navy", "000080",
		"oldlace", "FDF5E6",
		"olive", "808000",
		"olivedrab", "6B8E23",
		"orange", "FFA500",
		"orangered", "FF4500",
		"orchid", "DA70D6",
		"palegoldenrod", "EEE8AA",
		"palegreen", "98FB98",
		"paleturquoise", "AFEEEE",
		"palevioletred", "DB7093",
		"papayawhip", "FFEFD5",
		"peachpuff", "FFDAB9",
		"peru", "CD853F",
		"pink", "FFC0CB",
		"plum", "DDA0DD",
		"powderblue", "B0E0E6",
		"purple", "800080",
		"rebeccapurple", "663399",
		"red", "FF0000",
		"rosybrown", "BC8F8F",
		"royalblue", "4169E1",
		"saddlebrown", "8B4513",
		"salmon", "FA8072",
		"sandybrown", "F4A460",
		"seagreen", "2E8B57",
		"seashell", "FFF5EE",
		"sienna", "A0522D",
		"silver", "C0C0C0",
		"skyblue", "87CEEB",
		"slateblue", "6A5ACD",
		"slategray", "708090",
		"snow", "FFFAFA",
		"springgreen", "00FF7F",
		"steelblue", "4682B4",
		"tan", "D2B48C",
		"teal", "008080",
		"thistle", "D8BFD8",
		"tomato", "FF6347",
		"turquoise", "40E0D0",
		"violet", "EE82EE",
		"wheat", "F5DEB3",
		"white", "FFFFFF",
		"whitesmoke", "F5F5F5",
		"yellow", "FFFF00",
		"yellowgreen", "9ACD32"
	)

}
; ---------------------------------------------------------------------------

; class DisplayManager {
; 	static Instances := Map()
; 	static ScreenProps := {
; 		width: A_ScreenWidth/3,
; 		topMargin: A_ScreenHeight/2,
; 		stackMargin: 30
; 	}

; 	static RegisterGui(guiObj, owner := "") {
; 		this.Instances[guiObj.Hwnd] := {
; 			guiObj: guiObj,
; 			owner: owner
; 		}
; 		this.RepositionAll()
; 	}

; 	static UnregisterGui(hwnd) {
; 		this.Instances.Delete(hwnd)
; 		this.RepositionAll()
; 	}

; 	static GetExistingDisplays() {
; 		return this.Instances.Clone()
; 	}

; 	static RepositionAll() {
; 		existingCount := this.Instances.Count
; 		for i, display in this.Instances {
; 			y := this.ScreenProps.topMargin + (i-1)*this.ScreenProps.stackMargin
; 			display.guiObj.Show(Format("y{1}", y))
; 		}
; 	}

; 	static SetupGuiDefaults(guiObj) {
; 		guiObj.Opt("+AlwaysOnTop -Caption +ToolWindow")
; 		guiObj.MarginX := 0
; 		guiObj.BackColor := "0x161821"
; 		guiObj.SetFont("s10", "Segoe UI")
; 		return guiObj
; 	}
; }

; class StackedDisplay {
; 	stackMargin := 30
; 	width := A_ScreenWidth/3
; 	topMargin := A_ScreenHeight/2
; 	isWaiting := true
	
; 	__New() {
; 		this.displayGui := Gui("+AlwaysOnTop -Caption +ToolWindow")
; 		this.displayGui.MarginX := 0
; 		this.displayGui.SetFont("s10", "Segoe UI")
; 		this.displayGui.BackColor := "0x161821"
; 		this.hotkeyList := []  ; Track hotkeys for cleanup
; 	}

; 	AddOption(text, index, total, command) {
		
; 		; Create GUI control
; 		this.displayGui.AddEdit(Format("x0 Center w{1} -E0x200 Background{2} c0x1EFF00", 
; 			this.width, 
; 			this.displayGui.BackColor), 
; 			text)
		
; 		; Set up hotkey
; 		HotIfWinActive("ahk_id " this.displayGui.Hwnd)
; 		hotkeyFn := this.SelectOption.Bind(this, command)
; 		Hotkey("F" index, hotkeyFn)
; 		this.hotkeyList.Push({key: "F" index, fn: hotkeyFn})
		
; 		; Show the GUI
; 		this.displayGui.Show(Format("y{1} AutoSize", 
; 			this.topMargin + (index-1)*this.stackMargin))
			
; 		return this.displayGui
; 	}
	
; 	SelectOption(command, *) {
; 		this.CleanupHotkeys()
; 		Sleep(A_Delay * 5)
; 		this.displayGui.Hide()
; 		this.displayGui.Destroy()
; 		return command
; 	}
	
; 	CleanupHotkeys() {
; 		; HotIfWinActive("ahk_id " this.displayGui.Hwnd)
; 		for hotkey in this.hotkeyList {
; 			try Hotkey(hotkey.key, hotkey.fn, "Off")
; 		}
; 		; HotIf()
; 	}

; 	WaitForSelection(selectedCommand := "") {
; 		; selectedCommand := ""
		
; 		; Wait for window to close or selection
; 		try while !selectedCommand && WinExist(this.displayGui.Hwnd) {
; 		; while !selectedCommand {
; 			Sleep(50)
; 		}
		
; 		this.CleanupHotkeys()
; 		return selectedCommand
; 	}
; }
; class StackedDisplay {
; 	__New() {
; 		this.guis := []
; 		this.selected := false
; 		this.result := 0
; 	}

; 	/**
; 	 * Add an option to the display
; 	 * @param {String} text Text to display
; 	 * @param {Integer} value Value to return if selected
; 	 * @param {Integer} index Position in stack (1-based)
; 	 */
; 	AddOption(text, value, index) {
; 		guiObj := Gui("+AlwaysOnTop -Caption +ToolWindow")
; 		guiObj.SetFont("s10", "Segoe UI")
; 		guiObj.AddText("x10 y5", text)
		
; 		; Store data
; 		guiObj.value := value
		
; 		; Calculate position (centered, stacked)
; 		screenWidth := A_ScreenWidth
; 		screenHeight := A_ScreenHeight
; 		guiWidth := screenWidth / 3
; 		guiHeight := 30
; 		guiX := (screenWidth - guiWidth) / 2
; 		guiY := (screenHeight / 2) + ((index - 1) * guiHeight)
		
; 		guiObj.Show(Format("x{1} y{2} w{3} h{4}", guiX, guiY, guiWidth, guiHeight))
		
; 		; Add to tracking
; 		this.guis.Push(guiObj)
		
; 		; Setup hotkeys
; 		this.SetupHotkeys(guiObj, index)
; 	}

; 	/**
; 	 * Setup hotkeys for F-keys and clicks
; 	 * @param {Gui} guiObj GUI object to attach events to
; 	 * @param {Integer} index F-key number
; 	 */
; 	SetupHotkeys(guiObj, index) {
; 		; F-key hotkey
; 		HotIfWinExist("ahk_id " guiObj.Hwnd)
; 		Hotkey("F" index, this.HandleSelection.Bind(this, guiObj))

; 		; Click handler
; 		guiObj.OnEvent("Click", this.HandleSelection.Bind(this, guiObj))
; 	}

; 	/**
; 	 * Handle selection via F-key or click
; 	 * @param {Gui} guiObj Selected GUI
; 	 */
; 	HandleSelection(guiObj, *) {
; 		this.selected := true
; 		this.result := guiObj.value
; 		this.CleanupGuis()
; 	}

; 	/**
; 	 * Wait for user selection
; 	 * @param {Integer} timeout Timeout in milliseconds (0 = no timeout)
; 	 * @returns {Integer} Selected value or 0 if cancelled
; 	 */
; 	WaitForSelection(timeout := 0) {
; 		startTime := A_TickCount
; 		while !this.selected {
; 			if (timeout && (A_TickCount - startTime > timeout)) {
; 				this.CleanupGuis()
; 				return 0
; 			}
; 			Sleep(10)
; 		}
; 		return this.result
; 	}

; 	/**
; 	 * Clean up all GUI windows
; 	 */
; 	CleanupGuis() {
; 		for guiObj in this.guis
; 			guiObj.Destroy()
; 		this.guis := []
; 	}

; 	/**
; 	 * Clean up on object destruction
; 	 */
; 	__Delete() {
; 		this.CleanupGuis()
; 	}
; }
class StackedDisplay {
    width := A_ScreenWidth/3
    topMargin := A_ScreenHeight/2
    stackMargin := 30
    
    guis := []
    selected := false
    result := 0

    __New() {
        this.guis := []
    }

    /**
     * Adds an option to the stacked display
     * @param {String} text The text to display
     * @param {Integer} value The value to return if selected
     * @param {Integer} index Position in stack (1-based)
     * @returns {Gui} The created GUI object
     */
    AddOption(text, value, index) {
        gui := Gui("+AlwaysOnTop -Caption +ToolWindow")
        gui.SetFont("s10", "Segoe UI")
        gui.AddText("x10 y5", text)
        
        ; Store data
        gui.value := value
        
        ; Calculate position
        y := this.topMargin + (index-1)*this.stackMargin
        gui.Show(Format("y{1} w{2}", y, this.width))
        
        ; Add to tracking
        this.guis.Push(gui)
        
        ; Setup hotkey
        this.SetupHotkeys(gui, index)
        
        return gui
    }

    SetupHotkeys(gui, index) {
        ; F-key hotkey
        HotIfWinExist("ahk_id " gui.Hwnd)
        Hotkey("F" index, this.HandleSelection.Bind(this, gui))

        ; Click handler
        gui.OnEvent("Click", this.HandleSelection.Bind(this, gui))
    }

    HandleSelection(gui, *) {
        this.selected := true
        this.result := gui.value
        this.CleanupGuis()
    }

    WaitForSelection(timeout := 0) {
        startTime := A_TickCount
        while !this.selected {
            if (timeout && (A_TickCount - startTime > timeout)) {
                this.CleanupGuis()
                return 0
            }
            Sleep(10)
        }
        return this.result
    }

    CleanupGuis() {
        for gui in this.guis
            gui.Destroy()
        this.guis := []
    }

    __Delete() {
        this.CleanupGuis()
    }
}
; ---------------------------------------------------------------------------
; class CleanInputBox extends Gui {

; 	; Width     := Round(A_ScreenWidth  / 1920 * 1200)
; 	Width     := Round(A_ScreenWidth  / 3)
; 	TopMargin := Round(A_ScreenHeight / 1080 * 800)

; 	; DarkMode(BackgroundColor:='') {
; 	; 	Gui2.DarkMode(this, BackgroundColor)
; 	; 	return this
; 	; }

; 	; ; MakeFontNicer(fontSize := 15) {
; 	; MakeFontNicer(fontParams*) {
; 	; 	Gui2.MakeFontNicer(fontParams)
; 	; 	return this
; 	; }

; 	__New() {
; 		cibGui := Gui('AlwaysOnTop -Caption +Border')
; 		super.__New('AlwaysOnTop -Caption +Border')
; 		super.DarkMode()
; 		super.MakeFontNicer('s10', 'q3', 'cRed')
; 		this.MarginX := 0

; 		this.InputField := this.AddEdit('x0 Center -E0x200 Background' this.BackColor ' w' this.Width)

; 		this.Input := ''
; 		this.isWaiting := true
; 		this.RegisterHotkeys()
; 	}

; 	Show() => (super.Show('y' this.TopMargin ' w' this.Width), this)

; 	/**
; 	 * Occupy the thread until you type in your input and press
; 	 * Enter, returns this input
; 	 * @returns {String}
; 	 */
; 	WaitForInput() {
; 		this.Show()
; 		while this.isWaiting {
; 		}
; 		return this.Input
; 	}

; 	SetInput() {
; 		this.Input := this.InputField.Text
; 		this.isWaiting := false
; 		this.Finish()
; 	}

; 	SetCancel() {
; 		this.isWaiting := false
; 		this.Finish()
; 	}

; 	RegisterHotkeys() {
; 		HotIfWinactive('ahk_id ' this.Hwnd)
; 		Hotkey('Enter', (*) => this.SetInput(), 'On')
; 		Hotkey('CapsLock', (*) => this.SetCancel())
; 		this.OnEvent('Escape', (*) => this.SetCancel())
; 	}

; 	Finish() {
; 		HotIfWinactive('ahk_id ' this.Hwnd)
; 		Hotkey('Enter', 'Off')
; 		this.Minimize()
; 		this.Destroy()
; 	}
; }

class CleanInputBox {

	; Default settings
	static Defaults := {
		fontSize: 12,
		quality: 5,
		color: 'Blue',
		font: 'Consolas',
		width: Round(A_ScreenWidth / 3),
		topMargin: Round(A_ScreenHeight / 1080 * 800),
		backgroundColor: '0xA2AAAD'
	}

	; Instance properties
	gui := ""
	InputField := ""
	Input := ""
	isWaiting := true
	settings := Map()

	/**
	 * Handle direct calls to the class (e.g., CleanInputBox())
	 * @param {String} name Method name (empty for direct calls)
	 * @param {Array} params Parameters passed to the call
	 * @returns {String} User input or empty string if cancelled
	 */
	static __Call(name, params) {
		if (name = "") {  ; Called directly as a function
			instance := CleanInputBox(params*)
			return instance.WaitForInput()
		}
	}

	__New(p1 := "", p2 := "", p3 := "") {
		; Parse parameters into settings
		this.settings := this.ParseParams(p1, p2, p3)
		
		; Create GUI
		this.gui := Gui('+AlwaysOnTop -Caption +Border')
		
		; Apply styling using Gui2 methods
		this.gui.DarkMode(this.settings.Get('backgroundColor', CleanInputBox.Defaults.backgroundColor))
		
		; Set font
		this.gui.SetFont(
			's' this.settings.Get('fontSize', CleanInputBox.Defaults.fontSize) 
			' q' this.settings.Get('quality', CleanInputBox.Defaults.quality) 
			' c' this.settings.Get('color', CleanInputBox.Defaults.color),
			this.settings.Get('font', CleanInputBox.Defaults.font)
		)
		
		; Setup GUI properties
		this.gui.MarginX := 0

		; Add input field
		this.InputField := this.gui.AddEdit(
			'x0 Center -E0x200 Background' this.gui.BackColor 
			' w' this.settings.Get('width', CleanInputBox.Defaults.width)
		)

		; Setup event handlers
		this.RegisterHotkeys()

		; this.WaitForInput()
	}

	static WaitForInput(){
		return CleanInputBox().WaitForInput()
	}

	ParseParams(p1 := "", p2 := "", p3 := "") {
		settings := Map()
		
		; If first parameter is object/map, use as settings
		if IsObject(p1) {
			for key, value in (p1 is Map ? p1 : p1.OwnProps()) {
				settings[key] := value
			}
			return settings
		}

		; Otherwise only add parameters that were actually provided
		if (p1 != "")
			settings['fontSize'] := p1
		if (p2 != "")
			settings['color'] := (SubStr(p2, 1, 1) = 'c' ? p2 : 'c' p2)
		if (p3 != "")
			settings['quality'] := p3
			
		return settings
	}

	WaitForInput() {
		this.gui.Show('y' this.settings.Get('topMargin', CleanInputBox.Defaults.topMargin) 
			' w' this.settings.Get('width', CleanInputBox.Defaults.width))
			
		while this.isWaiting {
			Sleep(A_Delay)
		}
		return this.Input
	}

	RegisterHotkeys() {
		HotIfWinactive('ahk_id ' this.gui.Hwnd)
		Hotkey('Enter', (*) => (this.Input := this.InputField.Text, this.isWaiting := false, this.Finish()), 'On')
		Hotkey('CapsLock', (*) => (this.isWaiting := false, this.Finish()))
		this.gui.OnEvent('Escape', (*) => (this.isWaiting := false, this.Finish()))
	}

	Finish() {
		HotIfWinactive('ahk_id ' this.gui.Hwnd)
		Hotkey('Enter', 'Off')
		this.gui.Minimize()
		this.gui.Destroy()
	}
}

; ---------------------------------------------------------------------------
; ---------------------------------------------------------------------------
; ---------------------------------------------------------------------------

class Infos {
	static fontSize := 8
	static distance := 4
	static unit := A_ScreenDPI / 144
	static guiWidth := Infos.fontSize * Infos.unit * Infos.distance
	static maximumInfos := Floor(A_ScreenHeight / Infos.guiWidth)
	static spots := Infos._GeneratePlacesArray()
	static maxNumberedHotkeys := 12
	static maxWidthInChars := 110

	__text := ''
	text {
		get => this.__text
		set => this.__text := value
	}

	__New(text, autoCloseTimeout := 0) {
		this.gui := Gui('AlwaysOnTop -Caption +ToolWindow')
		this.autoCloseTimeout := autoCloseTimeout
		this.text := text
		this.spaceIndex := 0
		if !this._GetAvailableSpace() {
			this._StopDueToNoSpace()
			return
		}
		this._CreateGui()
		this._SetupHotkeysAndEvents()
		this._SetupAutoclose()
		this._Show()
	}

	_CreateGui() {
		this.gui.DarkMode()
		this.MakeFontNicer(Infos.fontSize ' cblue')
		this.gui.NeverFocusWindow()
		this.gcText := this.gui.AddText(, this._FormatText())
		return this
	}

	DarkMode(BackgroundColor := '') {
		this.gui.BackColor := BackgroundColor = '' ? '0xA2AAAD' : BackgroundColor
		return this
	}

	MakeFontNicer(fontSize := 20) {
		this.gui.SetFont('s' fontSize ' c0000ff', 'Consolas')
		return this
	}

	NeverFocusWindow() {
		WinSetExStyle('+0x08000000', this.gui)  ; WS_EX_NOACTIVATE
		return this
	}

	static DestroyAll(*) {
		for index, infoObj in Infos.spots {
			if (infoObj is Infos) {
				infoObj.Destroy()
			}
		}
	}

	static _GeneratePlacesArray() {
		availablePlaces := []
		loop Infos.maximumInfos {
			availablePlaces.Push(false)
		}
		return availablePlaces
	}

	ReplaceText(newText) {
		if !this.gui.Hwnd {
			return Infos(newText, this.autoCloseTimeout)
		}

		if StrLen(newText) = StrLen(this.gcText.Text) {
			this.gcText.Text := newText
			this._SetupAutoclose()
			return this
		}

		Infos.spots[this.spaceIndex] := false
		return Infos(newText, this.autoCloseTimeout)
	}

	Destroy(*) {
		if (!this.gui.Hwnd) {
			return false
		}
		this.RemoveHotkeys()
		this.gui.Destroy()
		if (this.spaceIndex > 0) {
			Infos.spots[this.spaceIndex] := false
		}
		return true
	}

	RemoveHotkeys() {
		hotkeys := ['Escape', '^Escape']
		if (this.spaceIndex > 0 && this.spaceIndex <= Infos.maxNumberedHotkeys) {
			hotkeys.Push('F' this.spaceIndex)
		}
		HotIfWinExist('ahk_id ' this.gui.Hwnd)
		for hk in hotkeys {
			try Hotkey(hk, 'Off')
		}
		HotIf()
	}

	_FormatText() {
		ftext := String(this.text)
		lines := ftext.Split('`n')
		; lines := StrSplit(ftext, '`n')
		if lines.Length > 1 {
			ftext := this._FormatByLine(lines)
		}
		else {
			ftext := this._LimitWidth(ftext)
		}

		return String(this.text).Replace('&', '&&')
		; return StrReplace(ftext,'&', '&&')
	}

	_FormatByLine(lines) {
		newLines := []
		for index, line in lines {
			newLines.Push(this._LimitWidth(line))
		}
		ftext := ''
		for index, line in newLines {
			if index = newLines.Length {
				ftext .= line
				break
			}
			ftext .= line '`n'
		}
		return ftext
	}

	_LimitWidth(ltext) {
		if StrLen(ltext) < Infos.maxWidthInChars {
			return ltext
		}
		insertions := 0
		while (insertions + 1) * Infos.maxWidthInChars + insertions < StrLen(ltext) {
			insertions++
			ltext := ltext.Insert('`n', insertions * Infos.maxWidthInChars + insertions)
		}
		return ltext
	}

	_GetAvailableSpace() {
		for index, isOccupied in Infos.spots {
			if !isOccupied {
				this.spaceIndex := index
				Infos.spots[index] := this
				return true
			}
		}
		return false
	}

	_CalculateYCoord() => Round(this.spaceIndex * Infos.guiWidth - Infos.guiWidth)

	_StopDueToNoSpace() => this.Destroy()

	_SetupHotkeysAndEvents() {
		HotIfWinExist('ahk_id ' this.gui.Hwnd)
		Hotkey('Escape', (*) => this.Destroy(), 'On')
		Hotkey('^Escape', (*) => Infos.DestroyAll(), 'On')
		if (this.spaceIndex > 0 && this.spaceIndex <= Infos.maxNumberedHotkeys) {
			Hotkey('F' this.spaceIndex, (*) => this.Destroy(), 'On')
		}
		HotIf()
		this.gcText.OnEvent('Click', (*) => this.Destroy())
		this.gui.OnEvent('Close', (*) => this.Destroy())
	}

	_SetupAutoclose() {
		if this.autoCloseTimeout {
			SetTimer(() => this.Destroy(), -this.autoCloseTimeout)
		}
	}

	_Show() => this.gui.Show('AutoSize NA x0 y' this._CalculateYCoord())
}



/**
 * @name SelectableMsgBox
 * @description Enhanced message box with selectable text
 * @version 1.0.0
 * @author OvercastBTC
 * @date 2025-03-15
 */

/**
 * Enhanced MsgBox with return value tracking
 * @param {...*} params Variable parameters:
 *    - Text: The message to display
 *    - Title: The window title
 *    - Options: Button configuration ("OK", "OKCancel", "YesNo", etc.)
 *    - Owner: Owner window handle
 * @returns {String} The button clicked: "OK", "Cancel", "Yes", "No", "Retry", "Abort", or "Ignore"
 */
MsgBox(params*) {
    ; Parse parameters based on MsgBox standard
    text := "", title := "", options := "", owner := ""
    result := ""
    
    ; Check if first parameter is text or options
    if (params.Length >= 1) {
        if (params[1] is Integer) || (InStr("OKCancel,YesNo,YesNoCancel,RetryCancel,AbortRetryIgnore", params[1])) {
            options := params[1]
        } else {
            text := params[1]
        }
    }
    
    ; Check additional parameters
    if (params.Length >= 2) {
        if (options) {
            text := params[2]
            if (params.Length >= 3)
                title := params[3]
        } else {
            title := params[2]
            if (params.Length >= 3)
                options := params[3]
        }
    }
    
    ; Check for owner window
    if (params.Length >= 4) {
        owner := params[4]
    }

    mbGui := Gui("+AlwaysOnTop +Owner" owner)
    mbGui.Title := title
    mbGui.SetFont("s10", "Segoe UI")
    
    ; Add edit control for selectable text
    label := mbGui.AddEdit("r3 w300 ReadOnly", text)
    
    ; Configure buttons based on options
    ; buttonRow := AddHorizontalButtonRow(mbGui, options)
    
    ; Show GUI and wait for result
    mbGui.Show()
    
    ; Wait for button click
    while !result {
        Sleep(10)
    }
    
    mbGui.Destroy()
    return result

    ; Helper method to add button row
    AddHorizontalButtonRow(guiObj, options) {
        buttons := ButtonRow.ParseButtons(options)
        buttonWidth := 80
        spacing := 10
        totalWidth := (buttons.Length * buttonWidth) + ((buttons.Length - 1) * spacing)
        startX := (300 - totalWidth) / 2  ; Center buttons (300 is edit width)
        
        for index, buttonText in buttons {
            x := startX + ((index - 1) * (buttonWidth + spacing))
            btn := guiObj.AddButton(Format("x{1} y+10 w{2}", x, buttonWidth), buttonText)
            btn.OnEvent("Click", (ctrl, *) => (result := ctrl.Text))
        }
    }
}

; Helper class for button management
class ButtonRow {
	static ParseButtons(options) {
		if InStr(options, "OKCancel")
			return ["OK", "Cancel"]
		else if InStr(options, "YesNo")
			return ["Yes", "No"]
		else if InStr(options, "YesNoCancel")
			return ["Yes", "No", "Cancel"]
		else if InStr(options, "RetryCancel")
			return ["Retry", "Cancel"]
		else if InStr(options, "AbortRetryIgnore")
			return ["Abort", "Retry", "Ignore"]
		return ["OK"]
	}
}
