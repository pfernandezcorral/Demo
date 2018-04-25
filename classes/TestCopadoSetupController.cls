@isTest
private class TestCopadoSetupController {
    @testSetup static void setupTestData(){
        TestUtilities.setTestSettingsEE();
    }

    static testMethod void test() {
        //user creation
        User u = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
                FirstName = 'first',
                LastName = 'last',
                Email = 'puser000@test.com',
                Username = 'puser000@test.com' + System.currentTimeMillis(),
                CompanyName = 'TEST',
                Title = 'title',
                Alias = 'alias',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US'
        );
        insert u;

        List<Org__c> orgCredentialList = new List<Org__c>();
        //add this org
        Org__c o = testMethodUtilities.create('this org', 'Production/Developer', '', '', '', '', System.now());
        orgCredentialList.add(o);
        //add a 2nd org
        Org__c o2 = testMethodUtilities.create('org2', 'Production/Developer', '', '', '', '', System.now());
        orgCredentialList.add(o2);
        //add a 3rd org
        Org__c o3 = testMethodUtilities.create('org3', 'Production/Developer', '', '', '', '', System.now());
        orgCredentialList.add(o3);

        insert orgCredentialList;

        //add a git repository
        Git_Repository__c g = testMethodUtilities.create('git 1','test un','test pw','https://git.com');
        insert g;

        //add a git snapshot
        Git_Backup__c s = testMethodUtilities.create('my first git snapshot', 'master', '', g, Date.today(), o);
        insert s;

        Deployment_Flow__c df = new Deployment_Flow__c();
        df.Name = 'Deployment Flow';
        df.Active__c = true;
        insert df;

        Copado_License__c lc = Copado_License__c.getInstance();
        lc.SetupOwnerId = u.Id;
        lc.Enable_CCM__c = true;
        lc.Enable_Copado__c = false;
        upsert lc;

        ApexPages.currentPage().getParameters().put('setOauth',o.Id);

        CopadoSetupController con = new CopadoSetupController();

        //retrieving the org credentials
        con.getExistingOrgCredentials();
        System.assertEquals(3,con.orgCredentialMap.size());

        //refreshing the org credential panels
        con.refreshOrgCredentialList();

        //creating new org credentials
        con.orgCredentials.Name = 'New Org';
        con.orgCredentials.Org_Type__c = 'Production/Developer';
        con.orgCredentials.Test_Frequency__c = 'Daily';
        con.createOrgCredentials();
        con.getExistingOrgCredentials();
        System.assertEquals(4,con.orgCredentialMap.size());

        //set oauth authentication
        con.doOauth();

        //get current user`s api key
        con.getAPIKey();

        //get git repos
        con.getGitRepos();

        //get git snapshots depend on the selected git repos
        con.selectedGitRepositories = 'none';
        con.getsGitSnapshots();  // it will cover if condition
        con.selectedGitRepositories = g.Id;
        con.getsGitSnapshots(); // it will cover else condition

        //open new git snapshot form
        con.openGitSnapshotForm();

        //creating new git snapshot
        con.createGitSnapshot(); // returned becuase name is null
        System.assertEquals(null,con.gitSnapshot.Name);
        con.gitSnapshot.Name = 'Git Snapshot';
        con.createGitSnapshot(); // returned because branch is null
        System.assertEquals(null,con.gitSnapshot.Branch__c);
        con.gitSnapshot.Branch__c = 'master';
        con.createGitSnapshot(); // returned because permission is null
        System.assertEquals(null,con.gitSnapshot.Git_Snapshot_Permissions__c);
        con.gitSnapshot.Git_Snapshot_Permissions__c = 'Allow Commit Only';
        con.createGitSnapshot(); // returned because org credential is null
        System.assertEquals(null,con.gitSnapshot.Org__c);
        con.gitSnapshot.Org__c = o.Id;
        con.createGitSnapshot(); // inserted git snapshot successfully

        //get deployment flows
        con.getDeploymentFlows();

        //get deployment flow steps depend on selected deployment flow
        con.selectedDeploymentFlow = 'none';
        con.getsDeploymentFlowSteps(); // covers if condition

        //open new deployment flow form
        con.openDeploymentFlowForm();

        //create new deployment flow
        con.createDeploymentFlow(); // returned becuase name is null
        System.assertEquals(null,con.deploymentFlow.Name);
        con.deploymentFlow.Name = 'New Deployment Flow';
        con.createDeploymentFlow(); // inserted deployment flow successfully

        //get deployment flow steps depend on selected deployment flow to cover else condition
        con.selectedDeploymentFlow = df.Id;
        con.getsDeploymentFlowSteps(); // covers else

        //open new deployment flow step to create new one
        con.openDeploymentFlowStepForm();

        //insert deployment flow step
        con.createDeploymentFlowSteps();

        //close deployment flow form
        con.closeDeploymentFlowForm();

        //close deployment flow step form
        con.closeDeploymentFlowStepsForm();

        //close git snapshot form
        con.closeGitSnapshotForm();
    }
}