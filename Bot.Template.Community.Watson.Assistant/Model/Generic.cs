using System;
using System.Collections.Generic;
using System.Text;

namespace Bot.Template.Community.Watson.Assistant.Model
{
    public class Generic
    {
        public string response_type { get; set; }
        public string text { get; set; }
        public string title { get; set; }
        public IList<Option> options { get; set; }
    }

}
