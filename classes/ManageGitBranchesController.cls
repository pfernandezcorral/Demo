global with sharing class ManageGitBranchesController {

    public class CopadoException extends Exception{}
    public Git_Repository__c gitRepo {get;set;}
    public String repoId {get;set;}
    public Boolean showError {get;set;}

    public ManageGitBranchesController() {
        // Show Destructive Changes Warning
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.DELETE_BRANCHES_WARNING));
        // Get RepositoryId from URL
        repoId = ApexPages.currentPage().getParameters().get('repoId');
        if(repoId == null) {
            showError = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.GIT_REPOSITORY_ID_NOT_FOUND));
        } else {
            for(Git_Repository__c gitRepository : [SELECT Id, Name, URI__c FROM Git_Repository__c WHERE Id = :repoId]) {
                gitRepo = gitRepository;
            }
            showError = false;
        }
    }

    public PageReference deleteGitBranches() {
        if(gitRepo.Id != null) {
            try {
            String deleteGitBranches = ApexPages.currentPage().getParameters().get('deleteGitBranches');
            String callURL = Settings.Server_URL + '/json/v1/deleteGitBranches/' + EncodingUtil.urlEncode(gitRepo.Id,'UTF-8');
                HttpResponse res = SfdxAPIHelper.callDxJob('POST', callURL, deleteGitBranches, true);
                String body = res.getBody();
                if(String.isNotBlank(body)){
                    CopadoNotificationHelper.copadoFrontAPIreponse r = (CopadoNotificationHelper.copadoFrontAPIreponse)JSON.deserialize(body,CopadoNotificationHelper.copadoFrontAPIreponse.Class);
                    if(String.isNotBlank(r.copadoJobId)) {
                        JobsManager.createRunningJob(r.CopadoJobId,CopadoNotificationHelper.DELETE_GIT_BRANCHES,null,'Starting...');
                    }
                }
            } catch (Exception e){
                throw new CopadoException('An error has occured while deleting branches. ' + e.getMessage());
            }
        }
        return null;
    }

    public PageReference refreshBranchCache(){
        if(String.isNotBlank(repoId)){
            SfdxAPI.retrieveBranchesFromRepository(repoId);
        }
        return null;
    }

    public PageReference cancel(){
        //return new PageReference('/'+repoId);
        return new ApexPages.StandardController(gitRepo).view();

    }
}