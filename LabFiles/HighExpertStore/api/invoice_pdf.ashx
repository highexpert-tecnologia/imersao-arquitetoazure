<%@ WebHandler Language="C#" Class="ApiInvoicePdf" %>
using System;using System.Data.SqlClient;using System.Web;using System.Text;
using HighExpertStore;using System.Collections.Generic;

public class ApiInvoicePdf : IHttpHandler {
  public void ProcessRequest(HttpContext c) {
    try {
      string token = c.Request["token"] ?? "";
      int orderId = 0; int.TryParse(c.Request["orderId"] ?? "0", out orderId);
      string orderNumber = c.Request["orderNumber"] ?? null;

      using (var conn = Db.GetConnection()) {
        conn.Open();
        var uid = Db.ValidateToken(token, conn);
        if (uid == null) { c.Response.StatusCode=401; c.Response.ContentType="application/json";
          c.Response.Write(Db.Json(new{error="Token invalido"})); return; }

        if (orderId == 0 && !string.IsNullOrEmpty(orderNumber)) {
          using (var f = new SqlCommand("SELECT Id FROM Orders WHERE OrderNumber=@on AND UserId=@u", conn)) {
            f.Parameters.AddWithValue("@on", orderNumber);
            f.Parameters.AddWithValue("@u", uid.Value);
            var x = f.ExecuteScalar(); if (x == null) { c.Response.StatusCode=404; c.Response.ContentType="application/json"; c.Response.Write(Db.Json(new{error="Pedido nao encontrado"})); return; }
            orderId = Convert.ToInt32(x);
          }
        }
        if (orderId == 0) { c.Response.StatusCode=400; c.Response.ContentType="application/json"; c.Response.Write(Db.Json(new{error="Informe orderId ou orderNumber"})); return; }

        string on="", address="", cep="", name="", email="";
        decimal subtotal=0m, discount=0m, shipping=0m, total=0m;

        using (var q = new SqlCommand(@"
          SELECT o.OrderNumber,o.Subtotal,o.Discount,o.Shipping,o.Total,o.Cep,o.Address,u.Name,u.Email
          FROM Orders o JOIN Users u ON u.Id=o.UserId
          WHERE o.Id=@o AND o.UserId=@u", conn)) {
          q.Parameters.AddWithValue("@o", orderId);
          q.Parameters.AddWithValue("@u", uid.Value);
          using (var r = q.ExecuteReader()) {
            if (!r.Read()) { c.Response.StatusCode=404; c.Response.ContentType="application/json"; c.Response.Write(Db.Json(new{error="Pedido nao encontrado"})); return; }
            on = r.GetString(0);
            subtotal = r.IsDBNull(1) ? 0m : r.GetDecimal(1);
            discount = r.IsDBNull(2) ? 0m : r.GetDecimal(2);
            shipping = r.IsDBNull(3) ? 0m : r.GetDecimal(3);
            total = r.GetDecimal(4);
            cep = r.IsDBNull(5) ? "" : r.GetString(5);
            address = r.IsDBNull(6) ? "" : r.GetString(6);
            name = r.GetString(7);
            email = r.GetString(8);
          }
        }

        var items = new List<InvoiceItem>();
        using (var qi = new SqlCommand(@"SELECT oi.Quantity,oi.UnitPrice,p.Name,p.Id
                                         FROM OrderItems oi JOIN Products p ON p.Id=oi.ProductId
                                         WHERE oi.OrderId=@o", conn)) {
          qi.Parameters.AddWithValue("@o", orderId);
          using (var r = qi.ExecuteReader()) {
            while (r.Read()) {
              items.Add(new InvoiceItem {
                Sku = "P" + r.GetInt32(3),
                Name = r.GetString(2),
                Qty = r.GetInt32(0),
                Unit = Math.Round(r.GetDecimal(1), 2)
              });
            }
          }
        }

        byte[] pdf = MinimalPdf.BuildInvoice(on, name, email, address, cep, subtotal, discount, shipping, total, items);

        c.Response.Clear();
        c.Response.BufferOutput = true;
        c.Response.ContentType = "application/pdf";
        c.Response.ContentEncoding = Encoding.ASCII;
        c.Response.AddHeader("Content-Disposition", "attachment; filename=invoice-" + on + ".pdf");
        c.Response.BinaryWrite(pdf);
        c.Response.Flush();
        c.ApplicationInstance.CompleteRequest(); // evita ThreadAbortException
      }
    } catch (Exception ex) {
      c.Response.StatusCode = 500;
      c.Response.ContentType = "application/json";
      c.Response.Write(HighExpertStore.Db.Json(new { error = ex.Message }));
    }
  }
  public bool IsReusable { get { return false; } }
}
