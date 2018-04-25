public with sharing class ManageSeleniumTestingExt {

	public List<UserStoryGroup> LuserGroups {get;set;}
	public String userStoryId {get;set;}
	public String isRegression {get;set;}
	public String flowId {get;set;}
	public User_Story__c userStory {get;set;}
	public List<String> LenvNames {get;set;}
	public Map<String,Environment__c> MenvByName {get;set;}
	public Selenium_Test_Group__c mockGroup {get;set;}
	public String title {get;set;}
	public Set<String> preloadedGroupOrgCredentials {get;set;}
	public Set<String> toBeDeletedGroupOrgCredentials {get;set;}
	public List<Id> Lgroups = new List<Id>();

	public class ApplicationException extends Exception {}

	public ManageSeleniumTestingExt () {

		if(!LicenseHelper.isCSTEnabled())throw new ApplicationException(Label.SELENIUM_NOT_ENABLED);

		mockGroup = new Selenium_Test_Group__c();
		LuserGroups = new List<UserStoryGroup>();
		MenvByName = new Map<String,Environment__c>();

		preloadedGroupOrgCredentials = new Set<String>();
		toBeDeletedGroupOrgCredentials = new Set<String>();

		userStoryId = ApexPages.currentPage().getParameters().get('usId');
		isRegression = ApexPages.currentPage().getParameters().get('regression');
		flowId = ApexPages.currentPage().getParameters().get('flowId');

		if (userStoryId != null) {
			userStory = [SELECT Id, Project__r.Deployment_Flow__c, Name FROM User_Story__c WHERE Id = :userStoryId];
			title = Label.USER_STORY;
		}
		else if (isRegression != null) {
			title = Label.REGRESSION;
		}

		//load most recently Selenium Settings used
		List<User_Story_Selenium_Test__c> Lsettings = [SELECT Id, Selenium_Test_Group__r.Selenium_Settings__c 
														 FROM User_Story_Selenium_Test__c
														WHERE CreatedByID = :UserInfo.getUserId()
														ORDER BY CreatedDate DESC LIMIT 1];
		if (!Lsettings.isEmpty()) {
			mockGroup.Selenium_Settings__c = Lsettings[0].Selenium_Test_Group__r.Selenium_Settings__c;
		}

		//load all available suites and org credentials as per the flow

		//first, retrieve all environments and their org credentials for the actual flow.
		Set<Id> Senv = new Set<Id>();
		LenvNames = new List<String>();
		if (userStory != null) {
			for (Deployment_Flow_Step__c dfs: [SELECT Source_Environment__c, Destination_Environment__c
												FROM Deployment_Flow_Step__c
											   WHERE Deployment_Flow_Step__c.Deployment_Flow__c = :userStory.Project__r.Deployment_Flow__c]) {

				Senv.add(dfs.Source_Environment__c);
				Senv.add(dfs.Destination_Environment__c);
			}

			for (Environment__c e: [SELECT Name FROM Environment__c WHERE Id IN :Senv ORDER BY Name]) {
				LenvNames.add(e.Name);
				MenvByName.put(e.Name, e);
			}
		}
		else if (isRegression != null) {
			for (Deployment_Flow_Step__c dfs: [SELECT Source_Environment__c, Destination_Environment__c
												FROM Deployment_Flow_Step__c
											   WHERE Deployment_Flow_Step__c.Deployment_Flow__c = :flowId]) {

				Senv.add(dfs.Source_Environment__c);
				Senv.add(dfs.Destination_Environment__c);
			}

			for (Environment__c e: [SELECT Name FROM Environment__c WHERE Id IN :Senv ORDER BY Name]) {
				LenvNames.add(e.Name);
				MenvByName.put(e.Name, e);
			}
		}

		List<Org__c> Lorg = [SELECT Id, Name, Environment__r.Name FROM Org__c WHERE Environment__c IN :Senv ORDER BY Environment__r.Name, Name];
		List<Selenium_Test_Suite__c> Lsts = [SELECT Id, Name FROM Selenium_Test_Suite__c ORDER BY Name];

		//let's populate the grid with all the suites and all environments
		for (Selenium_Test_Suite__c groupSuite: Lsts) {

			UserStoryGroup usg = new UserStoryGroup();
			usg.prevSelected = false;
			usg.selected = false;
			usg.suite = groupSuite;
			usg.Morgs = new Map<String,List<Orgs>>();
			
			for (String eName: LenvNames) {
				usg.Morgs.put(eName, new List<Orgs>());
			}
			LuserGroups.add(usg);
		}

		//let's put the org credentials in their respective column
		for (Org__c groupOrg: Lorg) {

			for (UserStoryGroup usg: LuserGroups) {

				if (usg.Morgs.containsKey(groupOrg.Environment__r.Name)) {
					List<Orgs> LorgTemp = usg.Morgs.get(groupOrg.Environment__r.Name);
					Orgs ot = new Orgs();
					ot.selected = false;
					ot.orgCred = groupOrg;
					LorgTemp.add(ot);
					usg.Morgs.put(groupOrg.Environment__r.Name, LorgTemp);
				}
			}
		}

		//now, let's pre-select the existing groups in the US or the Regression Groups

		if (userStory != null) {
			for (User_Story_Selenium_Test__c uTest: [SELECT Selenium_Test_Group__c, User_Story__c FROM User_Story_Selenium_Test__c WHERE User_Story__c = :userStory.Id]) {
				Lgroups.add(uTest.Selenium_Test_Group__c);
			}
		}
		if (isRegression != null) {
			for (Selenium_Test_Group__c selGroup: [SELECT Id FROM Selenium_Test_Group__c WHERE Type__c = :Label.REGRESSION_TEST]) {
				Lgroups.add(selGroup.Id);
			}
		}

		List<Selenium_Group_Test_Suite__c> Lsuites = [SELECT Selenium_Test_Suite__r.Name, Selenium_Test_Suite__c, Selenium_Test_Group__c
														FROM Selenium_Group_Test_Suite__c 
													   WHERE Selenium_Test_Group__c IN :Lgroups];

		List<Selenium_Group_Org_Credential__c> Lsgoc = [SELECT External_Id__c, Org_Credential__r.Name, Org_Credential__r.Environment__r.Name, Org_Credential__c, Selenium_Test_Group__c
															  FROM Selenium_Group_Org_Credential__c 
															 WHERE Selenium_Test_Group__c IN :Lgroups 
															 ORDER BY Org_Credential__r.Environment__r.Name];

		for (Selenium_Group_Test_Suite__c groupSuite: Lsuites) {

			for (UserStoryGroup usg: LuserGroups) {

				if (usg.suite.Id == groupSuite.Selenium_Test_Suite__c) {

					for (Selenium_Group_Org_Credential__c groupOrg: Lsgoc) {

						preloadedGroupOrgCredentials.add(groupOrg.External_Id__c);

						if (groupOrg.Selenium_Test_Group__c == groupSuite.Selenium_Test_Group__c) {

							for (String env: usg.Morgs.keySet()) {

								List<Orgs> orgsTmp = usg.Morgs.get(env);

								for (Orgs org: orgsTmp) {

									if (org.orgCred.Id == groupOrg.Org_Credential__c) {
										org.selected = true;
									}
								}
							}
						}
					}

					usg.prevSelected = true;
					usg.selected = true;
				}
			}
		}
	}

	public void Save () {

		createSeleniumGroups();	
		ApexPages.addMessage(new ApexPages.message(ApexPages.severity.CONFIRM, Label.SELENIUM_GROUPS_UPDATED));	
	}

	public PageReference Back () {

		if (isRegression != null) {
			return new PageReference('/'+ flowId);
		}
		else {
			return new PageReference('/'+ userStoryId);
		}
	}

	private void createSeleniumGroups () {

		List<Selenium_Test_Run__c> Lstr = new List<Selenium_Test_Run__c>();
		Map<String, Selenium_Group_Org_Credential__c> Msgoc = new Map<String, Selenium_Group_Org_Credential__c>();
		Map<String, Selenium_Test_Group__c> Mstg = new Map<String, Selenium_Test_Group__c>();
		Map<String, User_Story_Selenium_Test__c> Musst = new Map<String, User_Story_Selenium_Test__c>();
		List<Selenium_Group_Test_Suite__c> Lsgts = new List<Selenium_Group_Test_Suite__c>();
		List<String> LdeleteKeys = new List<String>();
		List<String> LstgFutureUpdate = new List<String>();
		Set<String> selectedGroupOrgCredentials = new Set<String>();
		toBeDeletedGroupOrgCredentials = new Set<String>();

		List<Selenium_Test_Run__c> listOfRuns = new List<Selenium_Test_Run__c>();

		for (UserStoryGroup usg: LuserGroups) {
			if (usg.selected) {

				for (String env: usg.Morgs.keySet()) {
					Selenium_Group_Test_Suite__c sgts = new Selenium_Group_Test_Suite__c();
					sgts.Selenium_Test_Suite__c = usg.suite.Id;

					Selenium_Test_Group__c externalIdGroup = new Selenium_Test_Group__c();

					Selenium_Test_Group__c stg = new Selenium_Test_Group__c();
                    stg.Manage_Test_Runs_manually__c = true;
					stg.Description__c = Label.GROUP_BY_SELENIUM_MANAGER;
                    stg.Environment__c = MenvByName.get(env).Id;
                    stg.Selenium_Settings__c = mockGroup.Selenium_Settings__c;

					//meaning_ at least one org credential was selected
					Boolean orgExists = false;
					for (Orgs orgTmp: usg.Morgs.get(env)) {
						if (orgTmp.selected) {
							orgExists = true;
						}
					}

					if (orgExists) {
						if (userStory != null) {
							stg.Type__c = Label.USER_STORY_TEST;
							stg.Name = (userStory.Name  + ' - ' + env).abbreviate(80);
							stg.External_Id__c = userStory.Id + '_' + stg.Environment__c;
							externalIdGroup.External_Id__c = userStory.Id + '_' + stg.Environment__c;
						}else if (isRegression != null) {
							stg.Type__c = Label.REGRESSION_TEST;
							stg.Name = (Label.REGRESSION_TEST + ' - ' + env).abbreviate(80);
							stg.External_Id__c = stg.Environment__c;
							externalIdGroup.External_Id__c = stg.Environment__c;
						}
                        
                        if(Mstg.containsKey(stg.External_Id__c))
	                        stg = Mstg.get(stg.External_Id__c);
						Mstg.put(stg.External_Id__c,stg);
                        
						LstgFutureUpdate.add(stg.External_Id__c);
						
						for (Orgs orgTmp: usg.Morgs.get(env)) {
							if (orgTmp.selected) {
								Selenium_Group_Org_Credential__c sgoc = new Selenium_Group_Org_Credential__c();
								sgoc.Org_Credential__c = orgTmp.orgCred.Id;
								sgoc.Selenium_Test_Group__r = externalIdGroup;
								sgoc.External_Id__c = '' + sgoc.Org_Credential__c + stg.External_Id__c;
								Msgoc.put(sgoc.External_Id__c, sgoc);
								selectedGroupOrgCredentials.add(sgoc.External_Id__c);
								preloadedGroupOrgCredentials.add(sgoc.External_Id__c);

                                // create a test run.
                                Selenium_Test_Run__c run = new Selenium_Test_Run__c();
                                run.Name = (usg.suite.Name+' '+orgTmp.orgCred.Name).abbreviate(80);
                                run.Org_Credential__c = sgoc.Org_Credential__c;
                                run.Selenium_Test_Suite__c = sgts.Selenium_Test_Suite__c;
                                run.Selenium_Test_Group__r = stg;
                                run.Selenium_Settings__c = mockGroup.Selenium_Settings__c;
                                listOfRuns.add(run);
                            }
						}
						
						if (userStory != null) {
							User_Story_Selenium_Test__c usst = new User_Story_Selenium_Test__c();
							usst.User_Story__c = userStory.Id;
							usst.Selenium_Test_Group__r = externalIdGroup;
							usst.Name = (Label.FEATURE + ' ' + userStory.Name + ' - ' + usg.suite.Name).abbreviate(80);
							usst.External_Id__c = userStoryId + '_' + stg.External_Id__c;
							Musst.put(usst.External_Id__c, usst);
						}

						sgts.Selenium_Test_Group__r = externalIdGroup;
						sgts.External_Id__c = '' + usg.suite + stg.External_Id__c;
						Lsgts.add(sgts);
					}
				}
			}else {
				//remove preoviously selected tests that were unselected in the User Story. Groups remain.
				if (usg.prevSelected == true && userStory != null) {
					//delete by naming convention
					String deleteKey = (Label.FEATURE + ' ' + userStory.Name + ' - ' + usg.suite.Name).abbreviate(80);
					LdeleteKeys.add(deleteKey);
				}
			}
		}

		Utilities.Secure_DML(Mstg.values(), Utilities.DML_Action.UPS, schema.Sobjecttype.Selenium_Test_Group__c, schema.sObjectType.Selenium_Test_Group__c.fields.External_Id__c);     
		Utilities.Secure_DML(Lsgts, Utilities.DML_Action.UPS, schema.Sobjecttype.Selenium_Group_Test_Suite__c, schema.sObjectType.Selenium_Group_Test_Suite__c.fields.External_ID__c);  
		Utilities.Secure_DML(Msgoc.values(), Utilities.DML_Action.UPS, schema.Sobjecttype.Selenium_Group_Org_Credential__c, schema.sObjectType.Selenium_Group_Org_Credential__c.fields.External_ID__c);  
		Utilities.Secure_DML(Musst.values(), Utilities.DML_Action.UPS, schema.Sobjecttype.User_Story_Selenium_Test__c, schema.sObjectType.User_Story_Selenium_Test__c.fields.External_ID__c);  

		for (String existing: preloadedGroupOrgCredentials) {
			if (!selectedGroupOrgCredentials.contains(existing)) {
				toBeDeletedGroupOrgCredentials.add(existing);
			}
		}
		Utilities.Secure_DML([SELECT Id FROM User_Story_Selenium_Test__c WHERE Name IN :LdeleteKeys], Utilities.DML_Action.DEL, schema.Sobjecttype.User_Story_Selenium_Test__c); 

		unbindTestRunsAndDeleteGroupCredentials();

        for(Selenium_Test_run__c r : listOfRuns) {
            // this External_ID__c must match SeleniumTestGroupTriggerHelper
            r.External_ID__c = r.Selenium_Test_Group__r.Id+'_'+r.Selenium_Test_Suite__c+'_'+r.Org_Credential__c;
            r.Selenium_Test_Group__c = r.Selenium_Test_Group__r.Id;
        }
		Utilities.Secure_DML(listOfRuns, Utilities.DML_Action.UPS, schema.Sobjecttype.Selenium_Test_run__c, schema.sObjectType.Selenium_Test_Run__c.fields.External_Id__c);
    }

	private void unbindTestRunsAndDeleteGroupCredentials ()  {

		Map<String,Id> deletedGroupOC = new Map<String,Id>();
		List<Selenium_Group_Org_Credential__c> Lsgoc = [SELECT Selenium_Test_Group__c, Org_Credential__c 
														  FROM Selenium_Group_Org_Credential__c
														 WHERE External_Id__c IN :toBeDeletedGroupOrgCredentials];
		for (Selenium_Group_Org_Credential__c sgoc: Lsgoc) {
			deletedGroupOC.put('' + sgoc.Selenium_Test_Group__c + sgoc.Org_Credential__c, sgoc.Selenium_Test_Group__c);
		}

		List<Selenium_Test_Run__c> Lstr = [SELECT Id, Selenium_Test_Group__c, Org_Credential__c
											 FROM Selenium_Test_Run__c
											WHERE Selenium_Test_Group__c IN :deletedGroupOC.values()];

		for (Selenium_Test_Run__c str: Lstr) {
			if (deletedGroupOC.containsKey('' + str.Selenium_Test_Group__c + str.Org_Credential__c)) {
				str.Selenium_Test_Group__c = null;
			}
		}

		Utilities.Secure_DML(Lstr, Utilities.DML_Action.UPD, schema.Sobjecttype.Selenium_Test_Run__c);
		Utilities.Secure_DML(Lsgoc, Utilities.DML_Action.DEL, schema.Sobjecttype.Selenium_Group_Org_Credential__c);
	}

	public class UserStoryGroup {
		public Boolean prevSelected {get;set;}
        public Boolean selected {get;set;}
        public Selenium_Test_Suite__c suite {get;set;}
        public Map<String,List<Orgs>> Morgs {get;set;}
    }

    public class Orgs {
    	public Boolean selected {get;set;}
    	public Org__c orgCred {get;set;}
    }
}