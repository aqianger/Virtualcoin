using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace VirtData.models
{
   public class richUserModel
    {
        public AspNetUsers anUser { get; set; }
        public tb_UserAccount UserAccount { get; set; }
    }
}
