using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace VirtData.models
{
   public class minUserModel
    {
        /// <summary>
        /// 用户ID
        /// </summary>
        public string Id { get; set; }
        /// <summary>
        /// Email,唯一
        /// </summary>
        public string Email { get; set; }
        /// <summary>
        /// 用户名，需唯一
        /// </summary>
        public string userName { get; set; }
        /// <summary>
        /// 手机号，可选
        /// </summary>
        public string phoneNumber { get; set; }
        /// <summary>
        /// 6位安全码
        /// </summary>
        public string Safetycode { get; set;
        }
        /// <summary>
        /// 推荐人ID
        /// </summary>
        public string Referee { get; set; }
        /// <summary>
        /// 1，微型机；2，中型机；3，大型机
        /// </summary>
        public int MinerType { get; set; }
    }
}
