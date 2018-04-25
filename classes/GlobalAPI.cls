/**
 * This class can be accessed outside of the manage package that allows users to manage Copado Licenses.
 * @author Mert YALTI
 * @version 1.0
 * @date 18.09.2017
 */
global with sharing class GlobalAPI {
	/**
	 * Returns Total Licenses, used licenses and available licenses in a wrapper class as a general license information
	 * @see CopadoLicenses
	 * @see LicenseManagerController
	 * @return CopadoLicenses wrapper
	 */
	global CopadoLicenses getLicenseInformation() {
		LicenseManagerController cont = new LicenseManagerController();

		CopadoLicenses licenseInfo = new CopadoLicenses();
		licenseInfo.totalNumberOfCopadoLicenses = cont.copadoLicensesAvailable;
		licenseInfo.totalNumberOfCCMLicenses = cont.ccmLicensesAvailable;
		licenseInfo.totalNumberOfCSTLicenses = cont.cstLicensesAvailable;
		licenseInfo.totalNumberOfCADLicenses = cont.cadLicensesAvailable;
		licenseInfo.totalNumberOfCCHLicenses = cont.cchLicensesAvailable;

		licenseInfo.usedCopadoLicenses = cont.copadoLicensesUsed;
		licenseInfo.usedCCMLicenses = cont.ccmLicensesUsed;
		licenseInfo.usedCSTLicenses = cont.cstLicensesUsed;
		licenseInfo.usedCADLicenses = cont.cadLicensesUsed;
		licenseInfo.usedCCHLicenses = cont.cchLicensesUsed;

		licenseInfo.availableCopadoLicenses = cont.copadoLicensesAvailable - cont.copadoLicensesUsed;
		licenseInfo.availableCCMLicenses = cont.ccmLicensesAvailable - cont.ccmLicensesUsed;
		licenseInfo.availableCSTLicenses = cont.cstLicensesAvailable - cont.cstLicensesUsed;
		licenseInfo.availableCADLicenses = cont.cadLicensesAvailable - cont.cadLicensesUsed;
		licenseInfo.availableCCHLicenses = cont.cchLicensesAvailable - cont.cchLicensesUsed;

		return licenseInfo;

	}
	/**
	 * In order to see which users have which licenses enabled.
	 * @see Schema
	 * @see SObjectField
	 * @return Returns list of assigned copado license
	 */
	global List<UserLicense> listCopadoLicenses() {
		String sObjectName = 'Copado_License__c';
		//Ignore the PermissionSet object for the PermissionSet Explorer
		if (sObjectName != Label.PERMISSION_SET_SOBJECT_NAME) {
			sObjectName = Settings.ns + sObjectName;
		}
		Map<String, String> d = new Map<String, String>();
		if (!Schema.getGlobalDescribe().containsKey(sObjectName)) {
			System.debug('INVALID OBJECT ' + sObjectName);
			return null;
		}
		Map<String, Schema.SObjectField> fields = Schema.getGlobalDescribe().get(sObjectName).getDescribe().SObjectType.getDescribe().fields.getMap();

		List<String> accessiblefields = new List<String>();

		for (Schema.SObjectField field : fields.values()) {
			accessiblefields.add(field.getDescribe().getName());
		}

		String allfields = '';

		for (String fieldname : accessiblefields) {
			allfields += fieldname + ',';
		}

		allfields = allfields.subString(0, allfields.length() - 1);

		d.put(Label.OBJECT, sObjectName);
		d.put(Label.FIELDS, allfields);

		String soqlString = 'SELECT ' + d.get(Label.FIELDS) + ' FROM ' + d.get(Label.OBJECT) + ' WHERE IsDeleted = FALSE ORDER BY Name DESC';

		List<UserLicense> licenseList = new List<UserLicense>();
		for (Copado_License__c cl : Database.query(soqlString)) {
			licenseList.add(new UserLicense(
			                    cl.SetupOwnerId,
			                    cl.Enable_CAD__c,
			                    cl.Enable_CCH__c,
			                    cl.Enable_CCM__c,
			                    cl.Enable_Copado__c,
			                    cl.Enable_CST__c
			                ));
		}
		return licenseList;

	}
	/**
	 * If the userID that passed as a License setup owner has already have a license assigned this method updates that license details
	 * Otherwise new license record is being created
	 * @param  license Copado License
	 * @return        Id of affected record (Update/Insert)
	 */
	global String upsertCopadoLicense(Id userId, UserLicense licenseDetails) {
		Settings__c s = Settings__c.getOrgDefaults();
		String sObjectName = 'Copado_License__c';
		//Ignore the PermissionSet object for the PermissionSet Explorer
		if (sObjectName != Label.PERMISSION_SET_SOBJECT_NAME) {
			sObjectName = Settings.ns + sObjectName;
		}
		Map<String, String> d = new Map<String, String>();
		if (!Schema.getGlobalDescribe().containsKey(sObjectName)) {
			System.debug('INVALID OBJECT ' + sObjectName);
			return null;
		}
		Map<String, Schema.SObjectField> fields = Schema.getGlobalDescribe().get(sObjectName).getDescribe().SObjectType.getDescribe().fields.getMap();

		List<String> accessiblefields = new List<String>();

		for (Schema.SObjectField field : fields.values()) {
			accessiblefields.add(field.getDescribe().getName());
		}

		String allfields = '';

		for (String fieldname : accessiblefields) {
			allfields += fieldname + ',';
		}

		allfields = allfields.subString(0, allfields.length() - 1);

		d.put(Label.OBJECT, sObjectName);
		d.put(Label.FIELDS, allfields);

		String soqlString = 'SELECT ' + d.get(Label.FIELDS) + ' FROM ' + d.get(Label.OBJECT) + ' WHERE SetupOwnerId = \'' + userId + '\' ORDER BY Name DESC LIMIT 1';
		Copado_License__c systemLicense;
		try {
			systemLicense = Database.query(soqlString);
		} catch (Exception e) {
			System.debug(e.getMessage());
		}

		try {
			if (systemLicense != null) {
				for (String f : d.get(Label.FIELDS).split(',')) {
					if (fields.get(f.trim()).getDescribe().isUpdateable()) {
						Object upsVal = licenseDetails.getField(f.trim());
						if (upsVal != null && upsVal instanceof Boolean && (Boolean)upsVal && (Boolean)systemLicense.get(f.trim()) != (Boolean)upsVal) {
							checkAvailabilityFromField(f.trim());
							systemLicense.put(f.trim(), (Boolean)upsVal);
						} else if (upsVal != null && upsVal instanceof Boolean ) {
							systemLicense.put(f.trim(), (Boolean)upsVal);
						} else if (upsVal != null && upsVal instanceof Id) {
							systemLicense.put(f.trim(), (Id)upsVal);
						} else if (upsVal != null && upsVal instanceof String) {
							systemLicense.put(f.trim(), (String)upsVal);
						}
					}
				}
				Utilities.Secure_DML(systemLicense, Utilities.DML_Action.UPD, schema.Sobjecttype.Copado_License__c);
				return 'UPDATED';
			} else {
				Copado_License__c license = new Copado_License__c();
				if (!licenseDetails.isCADenabled) {
					license.Enable_CAD__c = licenseDetails.isCADenabled;
				} else {
					checkAvailabilityFromField(s.Namespace__c+'Enable_CAD__c');
					license.Enable_CAD__c = licenseDetails.isCADenabled;
				}
				if (!licenseDetails.isCCHenabled) {
					license.Enable_CCH__c = licenseDetails.isCCHenabled;
				} else {
					checkAvailabilityFromField(s.Namespace__c+'Enable_CCH__c');
					license.Enable_CCH__c = licenseDetails.isCCHenabled;
				}
				if (!licenseDetails.isCCMenabled) {
					license.Enable_CCM__c = licenseDetails.isCCMenabled;
				} else {
					checkAvailabilityFromField(s.Namespace__c+'Enable_CCM__c');
					license.Enable_CCM__c = licenseDetails.isCCMenabled;
				}
				if (!licenseDetails.isCopadoEnabled) {
					license.Enable_Copado__c = licenseDetails.isCopadoEnabled;
				} else {
					checkAvailabilityFromField(s.Namespace__c+'Enable_Copado__c');
					license.Enable_Copado__c = licenseDetails.isCopadoEnabled;
				}
				if (!licenseDetails.isCSTenabled) {
					license.Enable_CST__c = licenseDetails.isCSTenabled;
				} else {
					checkAvailabilityFromField(s.Namespace__c+'Enable_CST__c');
					license.Enable_CST__c = licenseDetails.isCSTenabled;
				}
				license.SetupOwnerId = userId;

				Utilities.Secure_DML(license, Utilities.DML_Action.INS, schema.Sobjecttype.Copado_License__c);
				return 'INSERTED';
			}
		} catch (Exception ex) {
			throw new CopadoAPIException(ex.getMessage());
			System.debug(ex.getMessage());
		}
		return null;
	}
	/**
	 * Deletes Copado license from the system by using given licenseId
	 * @param  licenseId Copado License Id
	 * @return           result boolean
	 */
	global Boolean deleteCopadoLicense(Id userId) {
		List<Copado_License__c> license = new List<Copado_License__c>([SELECT Id FROM Copado_License__c WHERE SetupOwnerId = : userId]);
		try {
			Utilities.Secure_DML(license, Utilities.DML_Action.DEL, schema.Sobjecttype.Copado_License__c);
			return true;
		} catch (Exception ex) {
			throw new CopadoAPIException(ex.getMessage());
			return false;
		}
	}
	global class CopadoAPIException extends Exception {}
	/**
	 * Wrapper class for general Copado License information
	 */
	global class CopadoLicenses {
		//License totals
		global Integer totalNumberOfCopadoLicenses {get; set;}
		global Integer totalNumberOfCCMLicenses {get; set;}
		global Integer totalNumberOfCSTLicenses {get; set;}
		global Integer totalNumberOfCADLicenses {get; set;}
		global Integer totalNumberOfCCHLicenses {get; set;}
		//Used licenses
		global Integer usedCopadoLicenses {get; set;}
		global Integer usedCCMLicenses {get; set;}
		global Integer usedCSTLicenses {get; set;}
		global Integer usedCADLicenses {get; set;}
		global Integer usedCCHLicenses {get; set;}
		//Available licenses
		global Integer availableCopadoLicenses {get; set;}
		global Integer availableCCMLicenses {get; set;}
		global Integer availableCSTLicenses {get; set;}
		global Integer availableCADLicenses {get; set;}
		global Integer availableCCHLicenses {get; set;}

	}

	private Map<String, String> licenseFieldMapping = new Map<String, String> {
		'Enable_CAD__c' => 'isCADenabled',
		'Enable_CCH__c' => 'isCCHenabled',
		'Enable_CCM__c' => 'isCCMenabled',
		'Enable_Copado__c' => 'isCopadoEnabled',
		'Enable_CST__c' => 'isCSTenabled',
		'SetupOwnerId' => 'userId'
	};

	private String copadoLicenseLimitReached = Label.COPADO_LICENSE_LIMIT_REACHED;
	private String ccmLicenseLimitReached = Label.CCM_LICENSE_LIMIT_REACHED;
	private String cstLicenseLimitReached = Label.CST_LICENSE_LIMIT_REACHED;
	private String cadLicenseLimitReached = Label.CAD_LICENSE_LIMIT_REACHED;//DP Copado Agile Delivery
	private String cchLicenseLimitReached = Label.CCH_LICENSE_LIMIT_REACHED;

	global class UserLicense {
		global Boolean isCADenabled {get; set;}
		global Boolean isCCHenabled {get; set;}
		global Boolean isCCMenabled {get; set;}
		global Boolean isCopadoEnabled {get; set;}
		global Boolean isCSTenabled {get; set;}
		global Id userId {get; set;}

		global UserLicense(Id userId,
		                   Boolean isCADenabled,
		                   Boolean isCCHenabled,
		                   Boolean isCCMenabled,
		                   Boolean isCopadoEnabled,
		                   Boolean isCSTenabled) {
			this.userId = userId;
			this.isCADenabled = isCADenabled;
			this.isCCHenabled = isCCHenabled;
			this.isCCMenabled = isCCMenabled;
			this.isCopadoEnabled = isCopadoEnabled;
			this.isCSTenabled = isCSTenabled;
		}
		public Object getField(String fieldName) {
			Settings__c s = Settings__c.getOrgDefaults();
			if (fieldName == s.Namespace__c+'Enable_CAD__c') {
				return isCADenabled;
			}
			else if (fieldName == s.Namespace__c+'Enable_CCH__c') {
				return isCCHenabled;
			}
			else if (fieldName == s.Namespace__c+'Enable_CCM__c') {
				return isCCMenabled;
			}
			else if (fieldName == s.Namespace__c+'Enable_Copado__c') {
				return isCopadoEnabled;
			}
			else if (fieldName == s.Namespace__c+'Enable_CST__c') {
				return isCSTenabled;
			} else if (fieldName == 'SetupOwnerId') {
				return userId;
			}
			return null;
		}
	}
	private void checkAvailabilityFromField(String fieldName) {
		Settings__c s = Settings__c.getOrgDefaults();
		CopadoLicenses licenseInfo = getLicenseInformation();
		if (fieldName == s.Namespace__c+'Enable_CAD__c') {
			if (licenseInfo.availableCADLicenses <= 0) {
				throw new CopadoAPIException(cadLicenseLimitReached);
			}
		}

		else if (fieldName == s.Namespace__c+'Enable_CCH__c') {
			if (licenseInfo.availableCCHLicenses <= 0) {
				throw new CopadoAPIException(cchLicenseLimitReached);
			}
		}

		else if (fieldName == s.Namespace__c+'Enable_CCM__c') {
			if (licenseInfo.availableCCMLicenses <= 0) {
				throw new CopadoAPIException(ccmLicenseLimitReached);
			}
		}

		else if (fieldName == s.Namespace__c+'Enable_Copado__c') {
			if (licenseInfo.availableCopadoLicenses <= 0) {
				throw new CopadoAPIException(copadoLicenseLimitReached);
			}
		}

		else if (fieldName == s.Namespace__c+'Enable_CST__c') {
			if (licenseInfo.availableCSTLicenses <= 0) {
				throw new CopadoAPIException(cstLicenseLimitReached);
			}
		}
	}
}