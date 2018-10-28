using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace VirtData.models
{
   public class userInfoForAdmin
    {
        public string UserId { get; set; }
        public string Email { get; set; }
        public string UserName { get; set; }
        public string MinerType { get; set; }

        public DateTime created { get; set; }
        public string curGrade { get; set; }
        public string refUsername { get; set; }
        public decimal money { get; set; }

        public string PhoneNumber { get; set; }

        public decimal directAward { get; set; }
        public decimal indirectAward { get; set; }
        /// <summary>
        /// 推荐情况，几个A0....
        /// </summary>
        public string  Recommend { get; set; }
     
        public DateTime endTime { get; set; }
    }
}
