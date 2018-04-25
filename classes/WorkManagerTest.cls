/*
*   WorkManager Unit Tests
*   Created by: jgaviria@copa.do
*   Description: Unit Test for WorkManager Controller
*/
@isTest
private class WorkManagerTest {
    @testSetup static void setupTestData(){
        TestUtilities.getAllMultilicense();
    }
    static void setupTestDataDML(){
        testMethodUtilities.upsertOrgwideSettings();
        profile p = [select id from Profile where name = 'System Administrator'];
        User user1 = new User(firstname = 'Future', lastname = 'User',
            alias = 'xyz1', 
            email = 'copado-test-1@test.org',
            emailencodingkey = 'UTF-8', 
            languagelocalekey='en_US', 
            localesidkey='en_US', 
            profileid = p.Id, 
            timezonesidkey = 'America/Los_Angeles',
            username = 'copado-test-1+SCA1@test.org'
            );
        insert(user1);

        TestUtilities.assignLicense(UserInfo.getUserName(), true, true, true, true, true);
        TestUtilities.assignLicense(user1.username, true, true, true, true, true);
    }

	/*
        This Method will test the constructor for the 4 default panels, meaning there is no Configuration saved
        The user is part of the teams   
     */
	@isTest static void loadWorkManagerDefault() {
        setupTestDataDML();
        User u1 = [select id from user where username = 'copado-test-1+SCA1@test.org'];

        //Create Team and team members for user assigned to the sprint
        Team__c tTest = new Team__c();
        tTest.Active__c = true;
        insert tTest;

        Team_Member__c tm = new Team_Member__c();
        tm.Team__c = tTest.Id;
        tm.Member__c = u1.Id;
        insert tm;

        //Sprint To Use
        List<Sprint__c> sToInsert = new List<Sprint__c>();
        Sprint__c s = new Sprint__c();
        s.Start_Date__c = date.today().addDays(-8);
        s.End_Date__c = date.today().addDays(8);
        s.Team__c = tTest.Id;
        sToInsert.add(s);

        Sprint__c nextS = new Sprint__c();
        nextS.Start_Date__c = date.today().addDays(20);
        nextS.End_Date__c = date.today().addDays(28);
        nextS.Team__c = tTest.Id;
        sToInsert.add(nextS);

        insert sToInsert;

        Git_Repository__c gitRepo = new Git_Repository__c(name = 'gitRepo');
        insert gitRepo;   

        Environment__c env1 = new Environment__c(Name='Dev1 Environment',Type__c='Sandbox');
        insert env1;

        Org__c testOrg1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Sandbox', null, 'SFDC_OrgId', null, null, system.now(), env1.Id);
        testOrg1.Default_Credential__c = true;
        insert testOrg1; 

        Deployment_Flow__c flowCBM = CMTestMethodUtilities.createCBMFlow('CBM flow', true, gitRepo.Id, 'master');
        insert flowCBM;          

        Project__c testProject = CMTestMethodUtilities.createProject('test project');
        testProject.Deployment_Flow__c = flowCBM.Id;
        insert testProject;       

        Epic__c e = new Epic__c();
        insert e;

        List<User_Story__c> usList = new  List<User_Story__c>();
        //First User Story, in Backlog, no Sprint
        User_Story__c userStory = CMTestMethodUtilities.createUserStory('Backlog US');
        userStory.Environment__c = env1.Id;
        userStory.Org_Credential__c = testOrg1.Id;
        userStory.Project__c = testProject.Id;
        userStory.Sprint__c = null;
        userStory.Status__c = 'Backlog';
        userStory.Epic__c = e.Id;
        usList.add(userStory);

        //User Story In Sprint
        User_Story__c userStory2 = CMTestMethodUtilities.createUserStory('Draft US');
        userStory2.Environment__c = env1.Id;
        userStory2.Org_Credential__c = testOrg1.Id;
        userStory2.Project__c = testProject.Id;
        userStory2.Sprint__c = s.Id;
        userStory2.Status__c = 'Draft';
        usList.add(userStory2);

        //Add two extra us for backlog and backburner to Apply Ranks
        User_Story__c userStory3 = CMTestMethodUtilities.createUserStory('Stay at Backlog US');
        userStory3.Environment__c = env1.Id;
        userStory3.Org_Credential__c = testOrg1.Id;
        userStory3.Project__c = testProject.Id;
        userStory3.Sprint__c = null;
        userStory3.Status__c = 'Backlog';
        usList.add(userStory3);

        User_Story__c userStory4 = CMTestMethodUtilities.createUserStory('Stay at Backburner US');
        userStory4.Environment__c = env1.Id;
        userStory4.Org_Credential__c = testOrg1.Id;
        userStory4.Project__c = testProject.Id;
        userStory4.Sprint__c = null;
        userStory4.Status__c = 'Backburner';
        usList.add(userStory4);        

        insert usList;        

        Test.startTest();
            Test.setCurrentPageReference(ApexPages.currentPage()); 
            System.runAs(u1) {
                WorkManager wM = new WorkManager();
                //4 Panels must have been rendered
                system.assertEquals(4,wM.wpList.size());
                //now let's add an epic panel
                System.currentPageReference().getParameters().put('newPanelId', String.valueOf(e.Id));
                System.currentPageReference().getParameters().put('newPanelName', Settings.ns+'Epic__c');
                wM.createNewPanel();
                system.assertEquals(5,wM.wpList.size());
                //try to add it again,
                wM.createNewPanel(); 
                //Should not be added
                system.assertEquals(5,wM.wpList.size());
                //Now Add Draft Panel:
                System.currentPageReference().getParameters().put('newPanelId', '');
                wM.statusSelected = 'Draft';
                wM.createNewPanel();
                system.assertEquals(6,wM.wpList.size());
                //Hide Draft Panel
                System.currentPageReference().getParameters().put('panelId', 'Draft');
                System.currentPageReference().getParameters().put('panelType', Settings.ns+'Status__c');
                wM.hidePanel();
                // Panel is removed, if needed now will be queried
                system.assertEquals(5,wM.wpList.size());
                //Show Draft Panel, Let's start moving User Stories
                System.currentPageReference().getParameters().put('newPanelId', '');
                wM.statusSelected = 'Draft';
                wM.createNewPanel();
                //Add Cancelled Panel
                System.currentPageReference().getParameters().put('newPanelId', '');
                wM.statusSelected = 'Cancelled';
                wM.createNewPanel();
                system.assertEquals(6,wM.wpList.size());
                system.debug(wM.wpList);
                //Update Ranks = Json example:
                String rankJS = '{"logIds":["'+userStory3.Id+'"],"burnerIds":["'+userStory4.Id+'"]}';
                System.currentPageReference().getParameters().put('jsrank', rankJS);
                wM.updateRanks();                
                //Save State JSON looks Like:
                String jState = '{"pName":"","pWrappers":[{"pId":"Backlog","pType":"'+Settings.ns+'Status__c"},{"pId":"Backburner","pType":"'+Settings.ns+'Status__c"},{"pId":"'+s.Id+'","pType":"'+Settings.ns+'Sprint__c"},{"pId":"'+nextS.Id+'","pType":"'+Settings.ns+'Sprint__c"},{"pId":"'+e.Id+'","pType":"'+Settings.ns+'Epic__c"},{"pId":"Draft","pType":"'+Settings.ns+'Status__c"},{"pId":"Cancelled","pType":"'+Settings.ns+'Status__c"}]}';
                System.currentPageReference().getParameters().put('jsstate', jState);
                wM.savePanelState();
                //Static Json: this is how it should be looking like:
                String jsonMockUpdate = '{"sId":"Backlog","tId":"Cancelled","stype":"'+Settings.ns+'Status__c","ttype":"'+Settings.ns+'Status__c","usIds":["'+userStory.Id+'"]}';
                System.currentPageReference().getParameters().put('jsonUpdate', jsonMockUpdate);
                wM.updatePanels();
                system.debug(wM.wpList);
                //Now Let's move same one from one Cancelled to next Sprint
                jsonMockUpdate = '{"sId":"Cancelled","tId":"'+nextS.Id+'","stype":"'+Settings.ns+'Status__c","ttype":"'+Settings.ns+'Sprint__c","usIds":["'+userStory.Id+'"]}';
                System.currentPageReference().getParameters().put('jsonUpdate', jsonMockUpdate);
                wM.updatePanels();
                system.debug(wM.wpList);
                //Let's add a new Config and remove it
                System.currentPageReference().getParameters().put('sName', 'Test Config');
                wM.addNewConfig();
                wM.pTypeSelected = 'Test Config';
                wM.removeConfig();

            }
        Test.stopTest();


	}
	
}