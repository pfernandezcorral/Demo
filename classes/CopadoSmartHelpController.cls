/**
 * Global smart tips component
 * Marking is global since customers may use this in their own pages as well.
 * Global managed components can be used by end users
 * @see CopadoSmartHelpComponent
 * <pre>
 * {@code <copado:CopadoSmartHelpComponent />}
 * </pre>
 * @version 1.0
 * @author Mert YALTI
 *
 */
global class CopadoSmartHelpController  {
	@TestVisible private Set<String> removedTips {get; set;} // List of removed tips in order to avoid displaying them again
	global List<SmartHelp> helpList {get; set;} // List of tips to display
	global String vfPageName {get; set{
		vfPageName = vfPageName!=null ? vfPageName.replace('copado__', '') : value;
	} } // Current VF page name
	global String tipType {get; set;} // To display correct tip for grid selections. (MetadataType)
	global String tipKey {get; set;} // The apiName for the tip to remove from display list
	global Boolean showTips {get; set;} // Show entire tip panel if there is at least one tip created otherwise hide it
	global Boolean tipsAllowed {get; set;} // If Show_Copado_Tips__c field on user is checked tips will be displayed
	global copadoSmartHelpController() {
		tipsAllowed = [SELECT Show_Copado_Tips__c From User Where Id = :UserInfo.getUserId()][0].Show_Copado_Tips__c;
		System.debug(LoggingLevel.INFO,'***tipsAllowed :'+tipsAllowed);
		helpList = new List<SmartHelp>();
		removedTips = new Set<String>();

		showTips = false;
	}
	/**
	 * Adds always show type of tips to page when page load is completed
	 * @see SmartHelp
	 * @return PageReference
	 */
	global PageReference setHelpList() {
		System.debug(LoggingLevel.INFO,'***vfPageName :'+vfPageName);
		if (!tipsAllowed) return null;
		helpList = new List<SmartHelp>();
		for (Copado_Smart_Help__mdt csh : [SELECT
				Base_Page__c,
				DeveloperName,
				Help_Text__c,
				Id,
				Label,
				Triggering_Action__c,
				Triggering_Value__c
		FROM Copado_Smart_Help__mdt
		WHERE Base_Page__c = : vfPageName AND Triggering_Action__c = 'Always Show']) {
			SmartHelp sh = new SmartHelp(csh.DeveloperName, csh.Label, csh.Triggering_Action__c, csh.Triggering_Value__c, csh.Help_Text__c);
			helpList.add(sh);
		}
		if (helpList.size() > 0) {
			showTips = true;
		}
		System.debug(LoggingLevel.INFO,'***setTypeList:::helpList :'+helpList);
		return null;
	}
	/**
	 * To be able to identify tips properly following method converts tips list to tips map
	 * @see SmartHelp
	 * @return Map<String, SmartHelp>
	 */
	private Map<String, SmartHelp> convertHelpListToMap() {
		Map<String, SmartHelp> temp = new Map<String, SmartHelp>();
		for (SmartHelp sh : helpList) {
			temp.put(sh.apiName, sh);
		}
		return temp;
	}
	/**
	 * Removes tip from display list
	 * @return PageReference
	 */
	global PageReference removeTip() {
		if (!tipsAllowed) return null;
		if (String.isBlank(tipKey)) {
			return null;
		}
		Map<String, SmartHelp> temp = convertHelpListToMap();
		if (temp.containsKey(tipKey)) {
			temp.remove(tipKey);
			removedTips.add(tipKey);
			helpList = new List<SmartHelp>();
			helpList.addAll(temp.values());
		}
		return null;
	}
	/**
	 * Show tips by checking tip type
	 * This method is created particularly for grid selections
	 * @return PageReference
	 */
	global PageReference setTypeList() {
		System.debug('*** tipType : '+tipType);
		System.debug('*** tipsAllowed : '+tipsAllowed);
		System.debug('*** vfPageName : '+vfPageName);
		if(String.isBlank(vfPageName)){
			vfPageName = ApexPages.currentPage().getParameters().get('pageName');
		}
		if (!tipsAllowed || String.isBlank(tipType)) return null;
		Map<String, SmartHelp> temp = convertHelpListToMap();
		showTips = false;
		System.debug(LoggingLevel.INFO,'***setTypeList:::removedTips :'+removedTips);
		for (Copado_Smart_Help__mdt csh : [SELECT
				Base_Page__c,
				DeveloperName,
				Help_Text__c,
				Id,
				Label,
				Triggering_Action__c,
				Triggering_Value__c
		FROM Copado_Smart_Help__mdt
		WHERE Base_Page__c = : vfPageName AND Triggering_Action__c != 'Always Show'
		AND DeveloperName NOT IN: removedTips AND Triggering_Value__c = : tipType
		ORDER BY Triggering_Value__c]) {
			SmartHelp sh = new SmartHelp(csh.DeveloperName, csh.Label, csh.Triggering_Action__c, csh.Triggering_Value__c, csh.Help_Text__c);
			temp.put(csh.DeveloperName, sh);
		}
		System.debug(LoggingLevel.INFO,'***temp map :'+temp);
		if (temp.keySet().size() > 0) {
			showTips = true;
			helpList = new List<SmartHelp>();
			helpList.addAll(temp.values());
		}

		System.debug(LoggingLevel.INFO,'***setTypeList:::helpList :'+helpList);
		return null;
	}
	/**
	 * Wrapper class for tips
	 */
	global class SmartHelp {
		global String apiName {get; set;}
		global String label {get; set;}
		global String t_action {get; set;}
		global String t_value {get; set;}
		global String helpText {get; set;}

		global smartHelp(String apiName, String label, String t_action, String t_value, String helpText) {
			this.apiName = apiName;
			this.label = label;
			this.t_action = t_action;
			this.t_value = t_value;
			this.helpText = helpText;
		}
	}
}