/**
 * Resolve Conflicts Controller
 * Allows users to mark conflicted files in a promotion as AUTO RESOLVED or RESOLVED
 * When marked as AUTO RESOLVED, the Copado backend will auto resolve the component.
 * When marked as RESOLVED, the Copado backend will merge the file as it was saved by the user.
 * @see ResolveConflicts.page
 * @version 1.0
 * @author David VENEGAS
 * 
 */
public without sharing class ResolveConflictsController {

	public Promotion__c promotion {get; set;}
    public List<Attachment> attachments = new List<Attachment>();

    public List<Schema.FieldSetMember> getHeaderFields() {
        List<Schema.FieldSetMember> fields = SObjectType.Promotion__c.FieldSets.Copado_Header_Fields.getFields();
        return fields;
    }

    public Attachment attachmentToResolve {get;set;}

    public Boolean goToPromotion {get;set;}
    public String namespace {get;set;}

    /**
     * constructor
     * @return [description]
     */
    public ResolveConflictsController() {
        attachments = new List<Attachment>();
        attachmentToResolve = null;
        goToPromotion = false;

        namespace = Settings.ns;

        // Get URL promotionId parameter
        String promotionId = ApexPages.currentPage().getParameters().get('promotionId');
        if(String.isBlank(promotionId)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.CONFLICT_RESOLUTION_NO_PROMOTION));
            return;
        }
        // get promotion values
        try {
            String query = 'SELECT ';
            for(Schema.FieldSetMember field : this.getHeaderFields()) {
                String fieldPath = field.getFieldPath();
                if(fieldPath != 'Name')  {
                    query += fieldPath + ', ';
                }
            }
            query += ' Name FROM Promotion__c WHERE Id =:promotionId LIMIT 1';
            promotion = Database.query(query);
        } catch (Exception e) {
            System.debug(e);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
    }

    /**
     *  Called by an apex:repeat in the page.
     */
    public List<Attachment> getAttachments() {
        if(promotion == null || !attachments.isEmpty()) {
            return attachments;
        }
        attachments = [SELECT Id, Name, ParentId FROM Attachment WHERE ParentId = :promotion.Id AND (Name LIKE 'AUTO RESOLVED%' OR Name LIKE 'RESOLVED%' OR NAME LIKE 'US-%') ORDER BY CreatedDate LIMIT 1000]; 
        return attachments;
    }

    /*
     *  Selects an attachment from the list and saves it in the attachmentToResolve variable
     *  The attachmentToResolve variable is used by the CodeMirror text editor
     */
    public void openAttachment() {
        String attIndex = Apexpages.currentPage().getParameters().get('attIndex');
        if(attIndex != null && attachments[Integer.valueOf(attIndex)] != null) {
            attachmentToResolve = attachments[Integer.valueOf(attIndex)];
            System.debug('### openAttachment: '+attachmentToResolve.Name);
        }
    }

    /**
     *  Updates the attachment name to start with "AUTO RESOLVED"
     */
    public void saveAutoResolveAttachment() {
        String attIndex = Apexpages.currentPage().getParameters().get('attIndex');

        if(attIndex != null && Integer.valueOf(attIndex) != null) {
            Attachment att = attachments[Integer.valueOf(attIndex)];

            if(att.Name.startsWith('RESOLVED')) {
                att.Name = att.Name.replace('RESOLVED', 'AUTO RESOLVED');
            } else if(!att.Name.startsWith('AUTO RESOLVED')) {
                att.Name = 'AUTO RESOLVED ' + att.Name;
            }

            System.debug('### saveAutoResolvedAttachment: '+att.Name);
            attachments.set(Integer.valueOf(attIndex), att);
            Utilities.Secure_DML(att, Utilities.DML_Action.UPS, schema.Sobjecttype.Attachment);
        }
    }

    /**
     *  Updates the attachment name to start with "RESOLVED"
     */
    public void saveResolvedAttachment() {
        Integer index = 0;
        if(attachmentToResolve != null) {
            for(Attachment att : attachments) {
                if(att.Id == attachmentToResolve.Id) {
                    if(att.Name.startsWith('AUTO RESOLVED')) {
                        att.Name = att.Name.replace('AUTO RESOLVED', 'RESOLVED');
                    } else if(!att.Name.startsWith('RESOLVED')) {
                        att.Name = 'RESOLVED ' + att.Name;
                    }

                    System.debug('### saveResolvedAttachment: '+att.Name);
                    attachments.set(index, att); // The attachment is upserted via Javascript
                    break;
                }
                index = index + 1;
            }
        }
    }

    /**
     *  Checks that all attachments are marked as RESOLVED or AUTO RESOLVED. 
     *  If True the user is redirected to the Promotion page.
     */
    public void createDeployment() {
        for(Attachment att : attachments) {
            if(!att.Name.startsWith('RESOLVED') && !att.Name.startsWith('AUTO RESOLVED')) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.CONFLICT_RESOLUTION_PENDING));
                return;
            }
        }
        System.debug('### createDeployment');
        goToPromotion = true;
    }

}