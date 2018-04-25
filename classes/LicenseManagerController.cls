public with sharing class LicenseManagerController {
	public static String copadoURL = Settings.Server_URL;

	public Integer copadoLicensesAvailable {get; set;}
	public Integer ccmLicensesAvailable {get; set;}
	public Integer cstLicensesAvailable {get; set;}
	public Integer cadLicensesAvailable {get; set;} //DP Licencias Disponibles
	public Integer cchLicensesAvailable {get; set;}
	public Integer cbmBranchesAvailable {get; set;}
	public Integer copadoLicensesUsed {get; set;}
	public Integer ccmLicensesUsed {get; set;}
	public Integer cadLicensesUsed {get; set;} //DP Licencias Utilizadas
	public Integer cstLicensesUsed {get; set;}
	public Integer cchLicensesUsed {get; set;}
	public Integer cbmLicensesUsed {get; set;}
	public boolean enableMultiLicenses {get; set;}
	public List<LicenseManager> copadoUsage {get; set;}
	public List<LicenseManager> ccmUsage {get; set;}
	public List<LicenseManager> cstUsage {get; set;}
	public List<LicenseManager> cadUsage {get; set;} //DP Lista de License Manager con el Usage
	public List<LicenseManager> cchUsage {get; set;}
	public Map<Id, Copado_License__c> licenseMap {get; set;}

	public User dummyUser {get; set;} //this is used for the user lookup

	public boolean assignCopado {get; set;}
	public boolean assignCCM {get; set;}
	public boolean assignCST {get; set;}
	public boolean assignCAD {get; set;} //DP
	public boolean assignCCH {get; set;}

	public static final String copadoLicenseLimitReached = Label.COPADO_LICENSE_LIMIT_REACHED;
	public static final String ccmLicenseLimitReached = Label.CCM_LICENSE_LIMIT_REACHED;
	public static final String cstLicenseLimitReached = Label.CST_LICENSE_LIMIT_REACHED;
	public static final String cadLicenseLimitReached = Label.CAD_LICENSE_LIMIT_REACHED;//DP Copado Agile Delivery
	public static final String cchLicenseLimitReached = Label.CCH_LICENSE_LIMIT_REACHED;

	public LicenseManagerController() {
		//US-0001524 features are now handled by FMA/LMO standard features. No need to callout the backend.
		getLicenses();
		dummyUser = new User();
	}

	public void getLicenses() { //RECOUNT NEW LICENSES USED ON ORG
		copadoLicensesAvailable = FeatureManagement.checkPackageIntegerValue('EE_Licenses_Enabled');
		ccmLicensesAvailable = FeatureManagement.checkPackageIntegerValue('CCM_Licenses_Enabled');
		cstLicensesAvailable = FeatureManagement.checkPackageIntegerValue('CST_Licenses_Enabled');
		cadLicensesAvailable = FeatureManagement.checkPackageIntegerValue('CAD_Licenses_Enabled');
		cchLicensesAvailable = FeatureManagement.checkPackageIntegerValue('CCH_Licenses_Enabled');
		cbmBranchesAvailable = FeatureManagement.checkPackageIntegerValue('CBM_Branches');

		System.debug('*** copadoLicensesAvailable = ' + copadoLicensesAvailable);
		System.debug('*** ccmLicensesAvailable = ' + ccmLicensesAvailable);
		System.debug('*** cstLicensesAvailable = ' + cstLicensesAvailable);
		System.debug('*** cadLicensesAvailable = ' + cadLicensesAvailable);
		System.debug('*** cchLicensesAvailable = ' + cchLicensesAvailable);
		System.debug('*** cbmBranchesAvailable = ' + cbmBranchesAvailable);

		enableMultiLicenses = copadoLicensesAvailable >0 && (cadLicensesAvailable>0 || ccmLicensesAvailable>0 || cstLicensesAvailable>0 || cchLicensesAvailable>0);

		copadoLicensesUsed = 0;
		ccmLicensesUsed = 0;
		cstLicensesUsed = 0;
		cadLicensesUsed = 0;
		cchLicensesUsed = 0;
		List<Copado_License__c> licenses = new List<Copado_License__c>();
		licenseMap = new Map<Id, Copado_License__c>();
		copadoUsage = new List<LicenseManager>();
		ccmUsage = new List<LicenseManager>();
		cstUsage = new List<LicenseManager>();
		cadUsage = new List<LicenseManager>();
		cchUsage = new List<LicenseManager>();
		licenses = [SELECT Id, SetupOwnerId, SetupOwner.Name, Enable_CCM__c, Enable_CAD__c, Enable_CST__c, Enable_Copado__c, Enable_CCH__c FROM Copado_License__c ORDER BY SetupOwner.Name];
		if (licenses.size() > 0) {
			for (Copado_License__c l : licenses) {
				licenseMap.put(l.SetupOwnerId, l);
				if (l.Enable_Copado__c == true) {
					copadoUsage.add(new LicenseManager(l, 'copado', this));
					copadoLicensesUsed++;
				}
				if (l.Enable_CCM__c == true) {
					ccmUsage.add(new LicenseManager(l, 'ccm', this));
					ccmLicensesUsed++;
				}
				if (l.Enable_CST__c == true) {
					cstUsage.add(new LicenseManager(l, 'cst', this));
					cstLicensesUsed++;
				}
				if (l.Enable_CAD__c == true) {
					cadUsage.add(new LicenseManager(l, 'cad', this)); //DP**
					cadLicensesUsed++;
				}
				if (l.Enable_CCH__c == true) {
					cchUsage.add(new LicenseManager(l, 'cch', this));
					cchLicensesUsed++;
				}
			}
		}

		cbmLicensesUsed = [select count() from Deployment_Flow_Step__c where
													Deployment_Flow__r.Active__c=true and
													Deployment_Flow__r.Main_Branch__c!=null and
													Deployment_Flow__r.Git_Repository__c!=null and
													Branch__c!=null];
	}
	/*
	This method will return true if the license count is exceeded.
	False == Everything ok.
	*/
	public boolean licenseCountExceeded(String type) {
		if (type == 'copado')return (copadoLicensesUsed + 1) > copadoLicensesAvailable;
		if (type == 'ccm')return (ccmLicensesUsed + 1) > ccmLicensesAvailable;
		if (type == 'cst')return (cstLicensesUsed + 1) > cstLicensesAvailable;
		if (type == 'cad')return (cadLicensesUsed + 1) > cadLicensesAvailable;
		if (type == 'cch')return (cchLicensesUsed + 1) > cchLicensesAvailable;
		return true;
	}
	/*
	Take the user from the dummyUser object and assign them the relevant license(s)
	*/
	public void addUser() {
		if (dummyUser.ManagerId == null) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.MUST_SELECT_USER));
			return;
		}
		try {
			Boolean licenseLimitReached = false;
			if (licenseMap.keySet().contains(dummyUser.ManagerId)) {
				Copado_License__c license = licenseMap.get(dummyUser.ManagerId);
				if (license.Enable_Copado__c == false && assignCopado == true && licenseCountExceeded('copado')) {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, copadoLicenseLimitReached));
					licenseLimitReached = true;
				}
				if (license.Enable_CCM__c == false && assignCCM == true && licenseCountExceeded('ccm')) {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, ccmLicenseLimitReached));
					licenseLimitReached = true;
				}
				if (license.Enable_CST__c == false && assignCST == true && licenseCountExceeded('cst')) {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, cstLicenseLimitReached));
					licenseLimitReached = true;
				}
				if (license.Enable_CAD__c == false && assignCAD == true && licenseCountExceeded('cad')) {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, cadLicenseLimitReached));
					licenseLimitReached = true;
				}
				if (license.Enable_CCH__c == false && assignCCH == true && licenseCountExceeded('cch')) {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, cchLicenseLimitReached));
					licenseLimitReached = true;
				}
				if(licenseLimitReached){
					return;
				}
				license.Enable_Copado__c = assignCopado;
				license.Enable_CCM__c = assignCCM;
				license.Enable_CST__c = assignCST;
				license.Enable_CAD__c = assignCAD;
				license.Enable_CCH__c = assignCCH;//ERROR
				Utilities.Secure_DML(license, Utilities.DML_Action.UPD, schema.Sobjecttype.Copado_License__c);
			} else {
				if (assignCopado == true && licenseCountExceeded('copado')) {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, copadoLicenseLimitReached));
					licenseLimitReached = true;
				}
				if (assignCCM == true && licenseCountExceeded('ccm')) {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, ccmLicenseLimitReached));
					licenseLimitReached = true;
				}
				if (assignCST == true && licenseCountExceeded('cst')) {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, cstLicenseLimitReached));
					licenseLimitReached = true;
				}
				if (assignCAD == true && licenseCountExceeded('cad')) { //***DP**
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, cadLicenseLimitReached));
					licenseLimitReached = true;
				}
				if (assignCCH == true && licenseCountExceeded('cch')) {
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, cchLicenseLimitReached));
					licenseLimitReached = true;
				}
				if(licenseLimitReached){
					return;
				}
				Copado_License__c license = new Copado_License__c();
				license.Enable_Copado__c = assignCopado;
				license.Enable_CCM__c = assignCCM;
				license.Enable_CST__c = assignCST;
				license.Enable_CAD__c = assignCAD;
				license.Enable_CCH__c = assignCCH;
				license.SetupOwnerId = dummyUser.ManagerId;
				Utilities.Secure_DML(license, Utilities.DML_Action.INS, schema.Sobjecttype.Copado_License__c);
			}
			dummyUser = new User();
			assignCopado = false;
			assignCCM = false;
			assignCST = false;
			assignCAD = false;//**DP**
			assignCCH = false;
			getLicenses();
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.LICENSE_UPSERT_SUCCESSFUL));
		} catch (Exception e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, '' + e.getMessage()));
		}
	}

	// used this SOQL to check selected users active licenses to auto populate checkbox
	public void retrieveCopadoLicenses(){
		for(Copado_License__c cl : [SELECT Id, Enable_CCM__c, Enable_CAD__c, Enable_CST__c, Enable_Copado__c, Enable_CCH__c FROM Copado_License__c WHERE SetupOwnerId =: dummyUser.ManagerId Limit 1]){
			assignCopado = cl.Enable_Copado__c;
			assignCCM = cl.Enable_CCM__c;
			assignCST = cl.Enable_CST__c;
			assignCAD = cl.Enable_CAD__c;
			assignCCH = cl.Enable_CCH__c;
		}
	}

	public List<SelectOption> getLicenseTypes() {
		List<SelectOption> options = new List<SelectOption>();
		options.add(new SelectOption('StandardUserLookup', 'User'));
		options.add(new SelectOption('PartnerUserLookup', 'Partner User'));
		options.add(new SelectOption('CustomerSuccessUserLookup', 'Customer Portal User'));
		return options;
	}

	public class LicenseManager {
		public Copado_License__c license {get; set;}
		public String type {get; set;}
		LicenseManagerController outerClass;

		public LicenseManager(Copado_License__c l, String t, LicenseManagerController outerClass) {
			this.license = l;
			this.type = t;
			this.outerClass = outerClass;
		}
		public void removeAssignment() {
			try {
				if (type == 'copado')license.Enable_Copado__c = false;
				if (type == 'ccm')license.Enable_CCM__c = false;
				if (type == 'cst')license.Enable_CST__c = false;
				if (type == 'cad')license.Enable_CAD__c = false;
				if (type == 'cch')license.Enable_CCH__c = false;
				Utilities.Secure_DML(license, Utilities.DML_Action.UPD, schema.Sobjecttype.Copado_License__c);
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, Label.LICENSE_UPSERT_SUCCESSFUL));
				outerClass.getLicenses();
			} catch (Exception e) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, '' + e.getMessage()));
			}
		}

	}
}