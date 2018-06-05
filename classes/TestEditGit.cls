@isTest
private class TestEditGit {
    @testSetup static void setupData() {
        TestUtilities.setTestSettingsEE();
    }
    static testMethod void testSuccess() {
        testMethodUtilities.upsertOrgwideSettings();
		// Start with null GIT
        Git_Repository__c gitRepo = new Git_Repository__c();
        PageReference pref = Page.editOrg;
	    pref.getParameters().put('id',null);
	    Test.setCurrentPage(pref);
	    
	    
	    EditGit ext = new EditGit(new ApexPages.StandardController(gitRepo));
	    ext.git = testMethodUtilities.create('%$£GFDS!P@Copado_test','Username','PASSWORD','http://www.bitbucket.org/');
		pref = ext.save();
		system.assert(pref.getUrl() != Page.editOrg.getUrl());
		
		Git_Repository__c g = [select Id from Git_Repository__c where Name='%$£GFDS!P@Copado_test' limit 1];
		pref = Page.editOrg;
	    pref.getParameters().put('id',g.Id);
	    Test.setCurrentPage(pref);
		
		Test.startTest();
		String b = '{"Status":"Ok"}';
	    Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
		ext.validate();
		System.assert(TestMethodUtilities.hasMessage(Label.OK_CREDENTIALS));
		Test.stopTest();
    }
    static testMethod void testError() {
        testMethodUtilities.upsertOrgwideSettings();
		// Start with null GIT
        Git_Repository__c gitRepo = new Git_Repository__c();
        PageReference pref = Page.editOrg;
	    pref.getParameters().put('id',null);
	    Test.setCurrentPage(pref);
	    
	    
	    EditGit ext = new EditGit(new ApexPages.StandardController(gitRepo));
	    ext.git = testMethodUtilities.create('%$£GFDS!P@Copado_test2','Username','PASSWORD','http://www.bitbucket.org/');
		pref = ext.save();
		system.assert(pref.getUrl() != Page.editOrg.getUrl());
		
		Git_Repository__c g = [select Id from Git_Repository__c where Name='%$£GFDS!P@Copado_test2' limit 1];
		pref = Page.editOrg;
	    pref.getParameters().put('id',g.Id);
	    Test.setCurrentPage(pref);
		Test.startTest();
		String b = 'error';
	    Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
		ext.validate();
		System.assert(TestMethodUtilities.hasMessage(Label.WRONG_CREDENTIALS));
		Test.stopTest();
    }
    static testMethod void testExistingGitRepo() {
        testMethodUtilities.upsertOrgwideSettings();
		// Start with null GIT
        Git_Repository__c gitRepo = testMethodUtilities.create('%$£GFDS!P@Copado_test2','Username','PASSWORD','http://www.bitbucket.org/');
        insert gitRepo;
        PageReference pref = Page.editOrg;
	    pref.getParameters().put('id', gitRepo.Id);
	    Test.setCurrentPage(pref);
	    
	    EditGit ext = new EditGit(new ApexPages.StandardController(gitRepo));
		
		Test.startTest();
		String b = 'error';
	    Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
		ext.validate();
		System.assert(TestMethodUtilities.hasMessage(Label.WRONG_CREDENTIALS));
		Test.stopTest();
    }
    static testMethod void testSSH(){
        testMethodUtilities.upsertOrgwideSettings();
        Git_Repository__c gitRepo = testMethodUtilities.create('%$£GFDS!P@Copado_test2','Username','PASSWORD','git@test.org');
        insert gitRepo;
        PageReference pref = Page.viewGit;
	    pref.getParameters().put('id', gitRepo.Id);
	    Test.setCurrentPage(pref);
	    
	    EditGit ext = new EditGit(new ApexPages.StandardController(gitRepo));
		
		Test.startTest();
		system.assertEquals(false, ext.keyVisible);
        system.assertEquals(false, ext.hasKeys);
        system.assertEquals(true, ext.isSSHauthentication);
        system.assertEquals('', ext.dumypass);
        
        String b = '{"ok": "Keys created"}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
        PageReference resultRef = ext.createSSHKey();
        Attachment att1 = new Attachment(Name='id_rsa.pub', Body=Blob.valueOf('test'), ParentId=ext.git.Id);
        insert att1;
        system.assertEquals(new PageReference('/'+ext.git.Id).getUrl(), resultRef.getUrl());
        List<Attachment> result = new List<Attachment>();
        result = [select Id, Name, Body from Attachment where ParentId=:ext.git.Id and Name=:ext.KEYNAME];
        system.assertEquals(1, result.size());
        ext = new EditGit(new ApexPages.StandardController(gitRepo));
        system.assertEquals(false, ext.keyVisible);
        system.assertEquals(true, ext.hasKeys);
        
        
        ext.selectedKeyId = result.get(0).Id;
        ext.viewKey();
        system.assertEquals(true, ext.keyVisible);
        system.assertEquals(result[0].Body.toString(), ext.selectedKeyContent);
        system.assertEquals(new PageReference('/'+ext.git.Id).getUrl(), ext.hideSSHkey().getUrl());
        
        ext.selectedKeyId = result.get(0).Id;
        ext.viewKey();
        system.assertEquals(true, ext.keyVisible);
        ext.selectedKeyId = result.get(0).Id;
        system.assertEquals(new PageReference('/'+ext.git.Id).getUrl(), ext.deleteKey().getUrl());
        result = [select Id, Name, Body from Attachment where ParentId=:ext.git.Id and Name=:ext.KEYNAME];
        system.assertEquals(0, result.size());
                
        ext.deleteKey();
        result = new List<Attachment>();
        result = [select Id, Name, Body from Attachment where ParentId=:ext.git.Id and Name=:ext.KEYNAME];
        system.assertEquals(0, result.size());
        ext.getCommits();
        ext.deployCommits();
        ext.retrieveCommits();
        ext.goToManageGITBranches();
        Test.stopTest();
    }
}