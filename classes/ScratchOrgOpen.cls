public with sharing class ScratchOrgOpen {

    private String soId;
    public Boolean copadoJobFinished{get;set;}
    private String cJobId = '';
    public String slockerMessage {get; set;}
    private Boolean canOpen = false;
    public ScratchOrgOpen(){
        slockerMessage = 'Loading...';
        //This Page will require an Id of the Scratch Org to open
        soId = ApexPages.currentPage().getParameters().get('Id');
        //With this we see if there is a job already running for this User-Endpoint
        Copado_Notification__c cn = CopadoNotificationHelper.qInProgressCopadoNotification(CopadoNotificationHelper.DX_OPEN_ORG,soId);
        if(cn != null){
            cJobId = cn.Matching_Key__c;
        }
    }

    public PageReference rScratchOrgJob(){
        PageReference pr = null;
        try{
           if(soId != null && soId != ''){
              system.debug(soId);
                List<Org__c> org = [Select OwnerId, CreatedById from Org__c where Id =: soId];
                system.debug(org);
               if(org.size()>0 && (UserInfo.getUserId() != org[0].OwnerId && UserInfo.getUserId() != org[0].CreatedById)){
                   system.debug(org);
                   ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,'Only Owner or Creator can open this Org'));
                    copadoJobFinished = true;
                    canOpen = false;
                }else if(org.size() == 0){
                   system.debug('no org');
                   ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,'Org Credential does not exist or is not accessible'));
                    copadoJobFinished = true;
                    canOpen = false;
               }else{
                    canOpen = true;
                }
            }

            if(!canOpen){
                return pr;
            }
            if(cJobId == '' && soId != null && soId != ''){
                String s = SfdxAPI.orgOpen(soId);
                CopadoNotificationHelper.copadoFrontAPIreponse r = (CopadoNotificationHelper.copadoFrontAPIreponse)JSON.deserialize(s,CopadoNotificationHelper.copadoFrontAPIreponse.Class);
                system.debug(r);
                if(r.copadoJobId != null && r.copadoJobId != ''){
                    cJobId = r.copadoJobId;
                    //slockerMessage = r.ok;
                    Copado_Notification__c newCN = CopadoNotificationHelper.instCopadoNotification(CopadoNotificationHelper.PROGRESS_STATUS_COPADO, soId,CopadoNotificationHelper.DX_OPEN_ORG,cJobId);
                    Utilities.Secure_DML(newCN, Utilities.DML_Action.INS, schema.Sobjecttype.Copado_Notification__c);
                    copadoJobFinished = false;
                }else if(r.error != null && r.error != ''){
                    copadoJobFinished = true;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,r.error));

                }else if(r.ok != null && r.ok == 'AccessUrl Valid'){
                    List<Attachment> att = [SELECT Id, Body FROM Attachment WHERE ParentId =: soId AND Name = 'AccessUrl.txt' ORDER BY LastModifiedDate DESC];
                    if(att.size()>0){
                        pr = new PageReference(DeployAPI.decryptAPIKey(att[0].Body.toString()));
                        copadoJobFinished = true;
                    }
                }
            }else if(cJobId != ''){
                Copado_Notification__c c = CopadoNotificationHelper.qCopadoNotificationBycopadoJobId(cJobId);
                if(c.isFinished__c != null && c.isFinished__c){
                    if(c.isSuccess__c){
                        List<Attachment> att = [SELECT Id, Body FROM Attachment WHERE ParentId =: soId AND Name = 'AccessUrl.txt' ORDER BY LastModifiedDate DESC];
                        if(att.size()>0){
                            system.debug(att[0].Body.toString());
                            system.debug(DeployAPI.decryptAPIKey(att[0].Body.toString()));
                            pr = new PageReference(DeployAPI.decryptAPIKey(att[0].Body.toString()));
                            copadoJobFinished = true;
                        }
                    }else{
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,c.Message__c != null ? c.Message__c : c.status__c != null ? c.status__c : 'Could not open scratch org'));
                        copadoJobFinished = true;
                    }
                }else{
                    slockerMessage = c.status__c;
                    copadoJobFinished = false;
                }

            }else{
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,'Org Id Invalid'));
            }
        }catch(exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,e.getMessage()));
            copadoJobFinished = true;
        }
        return pr;
    }
}