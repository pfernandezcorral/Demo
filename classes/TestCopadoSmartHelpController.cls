@isTest
private class TestCopadoSmartHelpController {
	static testMethod void testTips() {
		Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
		User u = new User(Alias = 'standt', Email = 'myTester@testorg.com',
		                  EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
		                  LocaleSidKey = 'en_US', ProfileId = p.Id, Show_Copado_Tips__c = true,
		                  TimeZoneSidKey = 'America/Los_Angeles', UserName = 'myTester@testorg.com');

		System.runAs(u) {
			CopadoSmartHelpController handler = new CopadoSmartHelpController();
			handler.setTypeList();
			System.assertEquals(0,handler.helpList.size());
			handler.vfPageName = 'GitCommitChanges';
			List<Copado_Smart_Help__mdt> alwaysList = new List<Copado_Smart_Help__mdt>([SELECT
		                                   Base_Page__c,
		                                   DeveloperName,
		                                   Help_Text__c,
		                                   Id,
		                                   Label,
		                                   Triggering_Action__c,
		                                   Triggering_Value__c
		                                   FROM Copado_Smart_Help__mdt
		                                   WHERE Base_Page__c = : handler.vfPageName AND Triggering_Action__c = 'Always Show']);
			handler.tipType = 'Report';

			handler.setHelpList();
			System.assertEquals(alwaysList.size(),handler.helpList.size());
			List<Copado_Smart_Help__mdt> gridList = new List<Copado_Smart_Help__mdt>([SELECT
		                                   Base_Page__c,
		                                   DeveloperName,
		                                   Help_Text__c,
		                                   Id,
		                                   Label,
		                                   Triggering_Action__c,
		                                   Triggering_Value__c
		                                   FROM Copado_Smart_Help__mdt
		                                   WHERE Base_Page__c = : handler.vfPageName AND Triggering_Action__c != 'Always Show'
		                                           AND DeveloperName NOT IN: handler.removedTips AND Triggering_Value__c = : handler.tipType
		                                                   ORDER BY Triggering_Value__c]);

			handler.setTypeList();
			System.assertEquals(alwaysList.size() + gridList.size(),handler.helpList.size());
			if(!gridList.isEmpty()){
				handler.removeTip();
				handler.tipKey = gridList[0].DeveloperName;
				handler.removeTip();
				System.assertEquals(alwaysList.size() + gridList.size() -1,handler.helpList.size());
			} else{
				handler.removeTip();
			}
		}
	}
}