using Bot.Template.Community.Api.Watson.Assistant.Model;
using IBM.Cloud.SDK.Core.Authentication.Iam;
using IBM.Watson.Assistant.v2;
using IBM.Watson.Assistant.v2.Model;
using Microsoft.Bot.Builder;
using Microsoft.Bot.Schema;
using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace Bot.Template.Community.Api.Watson.Assistant.Bots
{
    public class WatsonBot : ActivityHandler
    {
        string apikey = "----";
        string url = "-----";
        string versionDate = "2019-02-28";
        string assistantId = "----";
        static string sessionId;
        string inputString = "";

        public WatsonBot()
        {
            CreateSession();
        }

        protected override async Task OnMessageActivityAsync(ITurnContext<IMessageActivity> turnContext, CancellationToken cancellationToken)
        {

            Response response = this.MessageWithContext(turnContext.Activity.Text, turnContext.Activity.Recipient.Id);

            foreach (Generic resp in response.output.generic)
            {
                switch (resp.response_type)
                {
                    case "text":
                        await turnContext.SendActivityAsync(MessageFactory.Text(response.output.generic[0].text), cancellationToken);
                        break;
                    case "option":

                        var reply = MessageFactory.Text(resp.title);

                        reply.SuggestedActions = new SuggestedActions();

                        reply.SuggestedActions.Actions = new List<CardAction>();

                        foreach (Option opt in resp.options)
                        {
                            reply.SuggestedActions.Actions.Add(new CardAction() { Title = opt.label, Type = ActionTypes.ImBack, Value = opt.label });
                        }


                        await turnContext.SendActivityAsync(reply, cancellationToken);
                        break;
                }
            }
        }

        protected override async Task OnMembersAddedAsync(IList<ChannelAccount> membersAdded, ITurnContext<IConversationUpdateActivity> turnContext, CancellationToken cancellationToken)
        {
            foreach (var member in membersAdded)
            {
                if (member.Id != turnContext.Activity.Recipient.Id)
                {
                    //await turnContext.SendActivityAsync(MessageFactory.Text($"Hello and welcome!"), cancellationToken);
                }
            }
        }



        #region Sessions
        public void CreateSession()
        {
            IamAuthenticator authenticator = new IamAuthenticator(
                apikey: apikey);

            AssistantService service = new AssistantService("2019-02-28", authenticator);
            service.SetServiceUrl(url);

            var result = service.CreateSession(
                assistantId: assistantId
                );

            sessionId = result.Result.SessionId;
        }

        public void DeleteSession()
        {
            IamAuthenticator authenticator = new IamAuthenticator(
                apikey: apikey);

            AssistantService service = new AssistantService("2019-02-28", authenticator);
            service.SetServiceUrl(url);

            var result = service.DeleteSession(
                assistantId: assistantId,
                sessionId: sessionId
                );

            //Console.WriteLine(result.Response);
        }
        #endregion

        #region Message with context
        public Response MessageWithContext(string utterance, string userid)
        {
            IamAuthenticator authenticator = new IamAuthenticator(
                apikey: apikey);

            AssistantService service = new AssistantService("2019-02-28", authenticator);
            service.SetServiceUrl(url);

            MessageContextSkills skills = new MessageContextSkills();
            MessageContextSkill skill = new MessageContextSkill();
            skill.UserDefined = new Dictionary<string, object>();
            //skill.UserDefined.Add("unidade", FUNC.unidade);
            //skill.UserDefined.Add("sexo", FUNC.sexo);
            //Test

            skills.Add("main skill", skill);

            var result = service.Message(
                assistantId: assistantId,
                sessionId: sessionId,
                input: new MessageInput()
                {
                    Text = utterance
                },
                context: new MessageContext()
                {
                    Global = new MessageContextGlobal()
                    {
                        System = new MessageContextGlobalSystem()
                        {
                            UserId = userid
                        }
                    },
                    Skills = skills
                }
                );

            Response response = JsonConvert.DeserializeObject<Response>(result.Response);
            return response;

            //Console.WriteLine(result.Response);
        }
        #endregion
    }

}
