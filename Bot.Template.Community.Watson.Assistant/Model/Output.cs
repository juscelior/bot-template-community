using System;
using System.Collections.Generic;
using System.Text;

namespace Bot.Template.Community.Watson.Assistant.Model
{
    public class Output
    {
        public IList<Generic> generic { get; set; }
        public IList<Intent> intents { get; set; }
        public IList<object> entities { get; set; }
    }

}
