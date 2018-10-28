using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.Mvc;
using VirtData;
using VirtData.models;

namespace virtual_Currency.Controllers
{
    [Authorize(Roles ="admin")]
    public class AdminController : Controller
    {
        Entities vm = new Entities();
        webapiresult result = new webapiresult();
        // GET: Admin
        public ActionResult Index()
        {
            return View();
        }
        public ActionResult Adduser(minUserModel user) {
            Regex reg = new Regex(@"^\w+([-+.]\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*$");

            if (!reg.IsMatch(user.Email)) {
                result.code = -1;
                result.msg = "邮箱格式不正确";
                return new JsonResult() { Data = result };
            }
             reg = new Regex(@"^(13[0-9]|14[5|7]|15[0|1|2|3|5|6|7|8|9]|18[0|1|2|3|5|6|7|8|9])\d{8}$");
            if (!reg.IsMatch(user.phoneNumber)) {
                result.code = -1;
                result.msg = "手机号码格式不正确";
                return new JsonResult() { Data=result};
            }
            if (vm.AspNetUsers.Any(a => a.Email.Equals(user.Email, StringComparison.InvariantCultureIgnoreCase))) {
                result.code = -1;
                result.msg = "此邮箱已存在";
                return new JsonResult() { Data = result };
            }
            if (vm.AspNetUsers.Any(a => a.PhoneNumber.Equals(user.phoneNumber, StringComparison.InvariantCultureIgnoreCase)))
            {
                result.code = -1;
                result.msg = "此手机号已存在";
                return new JsonResult() { Data = result };
            }
            return new JsonResult() { Data = result };
            // vm.AspNetUsers.Add(anUser);
            // vm.SaveChanges();
        }
    }
}