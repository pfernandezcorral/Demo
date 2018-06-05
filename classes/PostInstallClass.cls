global class PostInstallClass implements InstallHandler {
	public class CopadoInstallationException extends Exception {}
	global void onInstall(InstallContext context) {
		if(Schema.getGlobalDescribe().get('PushTopic').getDescribe().isDeletable())
			database.delete([SELECT Id, Name FROM PushTopic WHERE Name = 'CopadoNotifications'], false);

		if (context != NULL && (context.previousVersion() == NULL || context.previousVersion() != NULL && context.previousVersion().compareTo(new Version(10, 0)) < 0 )) {
			String userId = context.installerId() != null ? context.installerId() : UserInfo.getUserId() != null ? UserInfo.getUserId() : 'UnknownUser';
			String orgId = context.organizationId()  != null ? context.organizationId()  : UserInfo.getOrganizationId() != null ? UserInfo.getOrganizationId() : null;
			if (String.isBlank(orgId)) {
				throw new CopadoInstallationException('Could not identify organization Id.');
			}
			PostInstallClass.registerCryptoKey(orgId, userId);
		} else if (context != NULL && context.previousVersion() != NULL && context.previousVersion().compareTo(new Version(8, 50)) < 0) {
			List<Git_Repository__c> gitRepos = new List<Git_Repository__c>([SELECT Id, Password__c FROM Git_Repository__c WHERE Password__c != NULL]);
			try {
				database.update(gitRepos, false);
			} catch (Exception e) {
				System.debug(e.getMessage());
			}

		} else {
			List<Personal_Settings__c> allSettings = [SELECT Id, API_Key__c FROM Personal_Settings__c WHERE API_Key__c != NULL];
			for (Personal_Settings__c ps : allSettings) {
				if (ps.API_Key__c != NULL && ps.API_Key__c.length() < 40) {
					ps.API_Key__c = encryptAPIKey(ps.API_Key__c);
				}
			}

			database.update(allSettings, false);
		}
		//DX
		if (context != NULL && (context.previousVersion() == NULL || context.previousVersion() != NULL && context.previousVersion().compareTo(new Version(11, 0)) < 0 )) {
			ScheduleDxJob();
		}
	}
	private static void ScheduleDxJob(){
		//First Check if Job is already Scheduled:
		List<Crontrigger> cT = [SELECT Id, CronJobDetail.Name, CronJobDetail.JobType FROM Crontrigger WHERE CronJobDetail.Name =: SfdxSchedulable.JOB_NAME];
		if(!(cT.size()>0)){
			System.Schedule(SfdxSchedulable.JOB_NAME, SfdxSchedulable.CRON_EXP, new SfdxSchedulable());
		}
	}

	private static Blob cryptoKey {get{
		if (!String.isEmpty(Settings__c.getOrgDefaults().CryptoKey__c)) {
			return EncodingUtil.base64Decode(Settings__c.getOrgDefaults().CryptoKey__c);
		} else{
			String metaKey =  [SELECT Id, DeveloperName, Text_Field__c  FROM Copado_Protected_Settiing__mdt WHERE DeveloperName = 'Deprecated_Key' LIMIT 1].Text_Field__c;
			return EncodingUtil.base64Decode(metaKey);
		}
	} set;
	}
	private static String encryptAPIKey(String clearAPIKey) {
		if (String.isBlank(clearAPIKey))return null;
		Blob data = Blob.valueOf(clearAPIKey);
		return EncodingUtil.base64Encode(Crypto.encryptWithManagedIV('AES256', PostInstallClass.cryptoKey , data));
	}
	public class LogKey {
		public String key {get; set;}
	}
	@future(callout = true)
	private static void registerCryptoKey(String orgId, String uId) {
		DescribeSObjectResult settingObject= Schema.getGlobalDescribe().get(Settings.ns+'Settings__c').getDescribe();
		if(!settingObject.isAccessible()){
			return;
		}

		Settings__c s = Settings__c.getOrgDefaults();
		Boolean cryptoKeyRegistered = FALSE;
		Boolean encrptLegacy = FALSE;
		Map<String, SObjectField> settingFields = settingObject.fields.getMap();
		DescribeFieldResult namespaceDescription = settingFields.get(Settings.ns+'Namespace__c').getDescribe();
		if (namespaceDescription.isUpdateable() && namespaceDescription.isCreateable() && String.isEmpty(s.Namespace__c)) {
			s.Namespace__c = 'copado__';
			cryptoKeyRegistered = TRUE;
		}
		DescribeFieldResult cryptoDescription = settingFields.get(Settings.ns+'CryptoKEY__c').getDescribe();
		if (cryptoDescription.isUpdateable() && cryptoDescription.isCreateable() && String.isBlank(s.CryptoKEY__c) || Test.isRunningTest()) {

			String url = Settings.Server_URL + '/json/v1/registerKey';
			String key = EncodingUtil.base64Encode(Crypto.generateAesKey(256));

			LogKey orgKey = new LogKey();
			orgKey.key = key;
			HttpRequest req = new HttpRequest();
			req.setTimeout(120000);

			req.setHeader('userId', uId);
			req.setHeader('orgId', orgId);
			String sid = '<sessionId might change>';
			String cdate = Datetime.now().formatGMT('yyyy-MM-dd');
			String myData =  'Copado Deployer by Copado Ltd' + uId + orgId + sid + cdate;
			Blob hash = Crypto.generateDigest('MD5', Blob.valueOf(myData));
			req.setHeader('token', EncodingUtil.convertToHex(hash));
			req.setHeader('Accept', 'application/json');
			req.setHeader('Content-type', 'application/json');
			req.setBody(JSON.serialize(orgKey));
			req.setEndpoint(url);
			req.setMethod('POST');
			Http h = new Http();
			HttpResponse res = h.send(req);
			String body = res.getBody();
			Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(body);
			Boolean isSuccess = Boolean.valueOf(m.get('isSuccess'));
			Boolean isFinished = Boolean.valueOf(m.get('isFinished'));
			if (isSuccess && isFinished) {
				encrptLegacy = TRUE;
				s.CryptoKEY__c = key;
				cryptoKeyRegistered = TRUE;
			}

		}
		if (cryptoKeyRegistered ) {
			try {
				database.upsert(s, false);
			} catch (Exception e) {
				throw new CopadoInstallationException('Could not upsert Settings.');
			}
		}
		//encrypt existing api key if any.
		List<Personal_Settings__c> allSettings = [SELECT Id, API_Key__c FROM Personal_Settings__c WHERE API_Key__c != NULL];

		List<Git_Repository__c> gitRepos = new List<Git_Repository__c>([SELECT Id, Password__c FROM Git_Repository__c WHERE Password__c != NULL]);


		/**
		 * Old deprecated crypto key
		 * In order to decrypt legacy data we need this key
		 * and then by using this decrypted data we can encrypt them with a new crypto key that
		 * generated per Copado org.
		 */

		String metaKey =  [SELECT Id, DeveloperName, Text_Field__c  FROM Copado_Protected_Settiing__mdt WHERE DeveloperName = 'Deprecated_Key' LIMIT 1].Text_Field__c;
		Blob deprecatedCryptoKey = EncodingUtil.base64Decode(metaKey);
		// To encode legacy Git_Repository__c data with the new org specific encryption key.
		for (Git_Repository__c git : gitRepos) {
			try {
				Blob encryptedPw = EncodingUtil.base64Decode(git.Password__c);
				String tempPw = Crypto.decryptWithManagedIV('AES256', deprecatedCryptoKey, encryptedPw).toString();
				if(Schema.getGlobalDescribe().get(Settings.ns+'Git_Repository__c').getDescribe().fields.getMap().get(Settings.ns+'Password__c').getDescribe().isUpdateable())
					git.Password__c = tempPw;
			} catch (Exception e) {
				System.debug('Git_Repository__c decrypt - encrypt exception: ' + e.getMessage());
			}
		}
		// To encode legacy Personal_Settings__c data with the new org specific encryption key.
		for (Personal_Settings__c ps : allSettings) {
			if (ps.API_Key__c != NULL && ps.API_Key__c.length() < 40) {
				ps.API_Key__c = PostInstallClass.encryptAPIKey(ps.API_Key__c);
			} else {
				try {
					Blob encryptedKey = EncodingUtil.base64Decode(ps.API_Key__c);
					String tempAPI = Crypto.decryptWithManagedIV('AES256', deprecatedCryptoKey, encryptedKey).toString();
					if(Schema.getGlobalDescribe().get(Settings.ns+'Personal_Settings__c').getDescribe().fields.getMap().get(Settings.ns+'API_Key__c').getDescribe().isUpdateable())
						ps.API_Key__c = PostInstallClass.encryptAPIKey(tempAPI);
				} catch (Exception e) {
					System.debug('Personal_Settings__c decrypt - encrypt exception: ' + e.getMessage());
				}

			}
		}
		// To encode legacy External_CI_Setting__c data with the new org specific encryption key.
		List<External_CI_Setting__c> externalCItoUpdate = new List<External_CI_Setting__c>();
		for (External_CI_Setting__c xcis : [SELECT Id, Password__c, API_Token__c FROM External_CI_Setting__c WHERE Password__c != NULL OR API_Token__c != null]) {
			if (xcis.Password__c != NULL) {
				try {
					Blob encryptedPw = EncodingUtil.base64Decode(xcis.Password__c);
					String tempPw = Crypto.decryptWithManagedIV('AES256', deprecatedCryptoKey, encryptedPw).toString();
					if(Schema.getGlobalDescribe().get(Settings.ns+'External_CI_Setting__c').getDescribe().fields.getMap().get(Settings.ns+'Password__c').getDescribe().isUpdateable())
						xcis.Password__c = tempPw;
				} catch (Exception e) {
					System.debug('External_CI_Setting__c pw decrypt - encrypt exception: ' + e.getMessage());
				}
			}
			if (xcis.API_Token__c != NULL) {
				try {
					Blob encryptedToken = EncodingUtil.base64Decode(xcis.API_Token__c);
					String tempPw = Crypto.decryptWithManagedIV('AES256', deprecatedCryptoKey, encryptedToken).toString();
					xcis.API_Token__c = tempPw;
				} catch (Exception e) {
					System.debug('External_CI_Setting__c token decrypt - encrypt exception: ' + e.getMessage());
				}
			}
			externalCItoUpdate.add(xcis);
		}
		try {
			database.update(externalCItoUpdate , false);
			database.update(gitRepos, false);
			database.update(allSettings, false);
		} catch (Exception ex) {
			System.debug(ex.getMessage());
		}
	}
}