@isTest
private class TestMassAddToReleaseExtension {

    static testMethod void massAddBySprint() {
        Project__c testProject = CMTestMethodUtilities.createProject('My Project');
        insert testProject;
        Release__c testRelease = CMTestMethodUtilities.createRelease('My Release');
        testRelease.Project__c = testProject.Id;
        insert testRelease;
        Sprint__c sprint1 = CMTestMethodUtilities.createSprint('Sprint1');
       	sprint1.Project__c = testProject.Id;
        insert sprint1;
        Sprint__c sprint2 = CMTestMethodUtilities.createSprint('Sprint2');
       	sprint2.Project__c = testProject.Id;
        insert sprint2;
        
        List<User_Story__c> sprint_stories = new List<User_Story__c>();
        for(Integer i=1; i<=5; i++){
        	User_Story__c us1 = new User_Story__c(Project__c=testProject.Id, Sprint__c=sprint1.Id, User_Story_Title__c='Title'+i, Status__c = 'Approved');
        	User_Story__c us2 = new User_Story__c(Project__c=testProject.Id, Sprint__c=sprint2.Id, User_Story_Title__c='Title'+i, Status__c = 'Approved');
        	if(i>3){
        		sprint_stories.add(us1);
        	}
        	else{
        		sprint_stories.add(us1);
        		sprint_stories.add(us2);
        	}
        }
        // We added 5 User Stories to Sprint 1
        // We added 3 User Stories to Sprint 2
        insert sprint_stories;
        System.debug(loggingLevel.Error, '*** sprint_stories: ' + sprint_stories);
        PageReference pref = Page.MassAddToRelease;
	    pref.getParameters().put('id',testRelease.id);
	    Test.setCurrentPage(pref);
	    
        MassAddToReleaseExtension ext = new MassAddToReleaseExtension(new ApexPages.StandardController(testRelease));
        
        List<MassAddToReleaseExtension.sprintWrapper> sprintsList = ext.wrapSprints(ext.sprints);
        system.assertEquals(2, sprintsList.size());
        Integer s1counter = 0;
        Integer s2counter = 0;
        System.debug(loggingLevel.Error, '*** sprintsList: ' + sprintsList);
        for(MassAddToReleaseExtension.sprintWrapper s : sprintsList){
        	if(s.sprint.Name==sprint1.Name)s1counter=s.usWrapper.size();
        	if(s.sprint.Name==sprint2.Name)s2counter=s.usWrapper.size();
        }
        system.assertEquals(5, s1counter);
        system.assertEquals(3, s2counter);
        
        // try to update (none selected) and expect error
        ext.massAdd_BySprint();
        CMTestMethodUtilities.hasMessage('You must select at least 1 User Story to add to the Release');
        
        // now we select 2 user stories (1 from each sprint) and add them to the release
        Boolean selected1 = false;
        Boolean selected2 = false;
        
        for(MassAddToReleaseExtension.sprintWrapper sw : ext.wrappedSprints){	
			for(MassAddToReleaseExtension.userStoryWrapper usw : sw.usWrapper){
				if(sw.sprint.Name==sprint1.Name && selected1==false){
					selected1=true;
					usw.selected=true;
				}
				if(sw.sprint.Name==sprint2.Name && selected2==false){
					selected1=true;
					usw.selected=true;
				}
			}
		}
        ext.massAdd_BySprint();
        CMTestMethodUtilities.hasMessage('Your selected User Stories have been added to the Release');
        for(MassAddToReleaseExtension.sprintWrapper sw : ext.wrappedSprints){	
			for(MassAddToReleaseExtension.userStoryWrapper usw : sw.usWrapper){
				system.assertEquals(false, usw.selected);
			}
		}
    }
}