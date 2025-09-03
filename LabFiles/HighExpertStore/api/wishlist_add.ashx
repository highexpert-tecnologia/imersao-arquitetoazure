<%@ WebHandler Language="C#" Class="ApiWishlistAdd" %>
using System;using System.Data.SqlClient;using System.Web;using HighExpertStore;

public class ApiWishlistAdd : IHttpHandler {
  public void ProcessRequest(HttpContext c) {
    c.Response.ContentType = "application/json";
    try {
      var body = Db.ReadBody(c.Request);
      dynamic p = new System.Web.Script.Serialization.JavaScriptSerializer().DeserializeObject(body);
      string token = p.ContainsKey("token") ? (string)p["token"] : "";
      int productId = p.ContainsKey("productId") ? Convert.ToInt32(p["productId"]) : 0;

      using (var conn = Db.GetConnection()) {
        conn.Open();
        var uid = Db.ValidateToken(token, conn);
        if (uid == null) { c.Response.StatusCode = 401; c.Response.Write(Db.Json(new { error = "Token inválido" })); return; }

        using (var cmd = new SqlCommand(@"
          IF NOT EXISTS(SELECT 1 FROM Wishlist WHERE UserId=@u AND ProductId=@p)
            INSERT INTO Wishlist(UserId,ProductId) VALUES(@u,@p)", conn)) {
          cmd.Parameters.AddWithValue("@u", uid.Value);
          cmd.Parameters.AddWithValue("@p", productId);
          cmd.ExecuteNonQuery();
        }

        c.Response.Write(Db.Json(new { ok = true }));
      }
    } catch (Exception ex) {
      c.Response.StatusCode = 500;
      c.Response.Write(Db.Json(new { error = ex.Message }));
    }
  }
  public bool IsReusable { get { return false; } }
}
