using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Text;

namespace HighExpertStore
{
    public class InvoiceItem
    {
        public string Sku;
        public string Name;
        public int Qty;
        public decimal Unit;
        public decimal LineSub { get { return Unit * Qty; } }
    }

    public static class MinimalPdf
    {
        private static string Escape(string s)
        {
            if (s == null) return "";
            return s.Replace("\\", "\\\\").Replace("(", "\\(").Replace(")", "\\)");
        }

        private static string Money(decimal v)
        {
            var s = v.ToString("0.00", CultureInfo.InvariantCulture);
            return "R$ " + s.Replace('.', ',');
        }

        public static byte[] BuildInvoice(
            string orderNumber,
            string customerName,
            string customerEmail,
            string customerAddress,
            string cep,
            decimal subtotal,
            decimal discount,
            decimal shipping,
            decimal total,
            IList<InvoiceItem> items)
        {
            var ms = new MemoryStream();
            // ASCII puro; sem BOM
            var writer = new StreamWriter(ms, Encoding.ASCII);

            Action<string> W = s => writer.Write(s);
            var offsets = new List<long>();

            Func<string, byte[]> ToAscii = s => Encoding.ASCII.GetBytes(s);

            Action<int> WriteObjHeader = id =>
            {
                writer.Flush();
                offsets.Add(ms.Position);
                W(id + " 0 obj\r\n");
            };

            // Cabeçalho PDF (apenas ASCII)
            W("%PDF-1.4\r\n");

            // 1: Catalog
            WriteObjHeader(1);
            W("<< /Type /Catalog /Pages 2 0 R >>\r\nendobj\r\n");

            // 2: Pages
            WriteObjHeader(2);
            W("<< /Type /Pages /Count 1 /Kids [3 0 R] >>\r\nendobj\r\n");

            // 4: Font
            WriteObjHeader(4);
            W("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\r\nendobj\r\n");

            // Conteúdo
            var content = new StringBuilder();
            Action<int,int,int,string> T = (xPos, yPos, size, text) =>
            {
                content.AppendFormat("BT /F1 {0} Tf 1 0 0 1 {1} {2} Tm ({3}) Tj ET\r\n",
                    size, xPos, yPos, Escape(text));
            };

            int curY = 800;
            T(50, curY, 18, "High Expert Store - INVOICE"); curY -= 24;
            T(50, curY, 12, "Pedido: " + orderNumber); curY -= 16;
            T(50, curY, 12, "Cliente: " + customerName + "  |  E-mail: " + customerEmail); curY -= 16;
            T(50, curY, 12, "Endereco: " + (customerAddress ?? "")); curY -= 16;
            T(50, curY, 12, "CEP: " + (cep ?? "")); curY -= 24;

            T(50, curY, 14, "Itens"); curY -= 18;
            T(50,  curY, 12, "Qtd");
            T(100, curY, 12, "Descricao");
            T(420, curY, 12, "Unitario");
            T(500, curY, 12, "Subtotal");
            curY -= 12;
            T(50, curY, 12, "______________________________________________________________");
            curY -= 14;

            foreach (var it in items)
            {
                int q = it.Qty <= 0 ? 1 : it.Qty;
                T(50,  curY, 12, q.ToString());
                T(100, curY, 12, it.Name ?? "");
                T(420, curY, 12, Money(it.Unit));
                T(500, curY, 12, Money(it.LineSub));
                curY -= 16;
                if (curY < 120) break; // uma pagina
            }

            curY -= 8;
            T(50, curY, 12, "______________________________________________________________"); curY -= 18;
            T(380, curY, 12, "Subtotal: " + Money(subtotal)); curY -= 16;
            T(380, curY, 12, "Desconto: " + Money(discount)); curY -= 16;
            T(380, curY, 12, "Frete: " + Money(shipping)); curY -= 18;
            T(380, curY, 14, "TOTAL: " + Money(total));

            var contentBytes = ToAscii(content.ToString());

            // 5: Content stream
            WriteObjHeader(5);
            W("<< /Length " + contentBytes.Length + " >>\r\nstream\r\n");
            writer.Flush();
            ms.Write(contentBytes, 0, contentBytes.Length);
            W("endstream\r\nendobj\r\n");

            // 3: Page
            WriteObjHeader(3);
            W("<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] ");
            W("/Resources << /Font << /F1 4 0 R >> >> ");
            W("/Contents 5 0 R >>\r\nendobj\r\n");

            // xref/trailer
            writer.Flush();
            long xrefPos = ms.Position;
            W("xref\r\n0 6\r\n");
            W("0000000000 65535 f \r\n");
            for (int i = 0; i < offsets.Count; i++)
            {
                string off = offsets[i].ToString("0000000000", CultureInfo.InvariantCulture);
                W(off + " 00000 n \r\n");
            }
            W("trailer << /Size 6 /Root 1 0 R >>\r\nstartxref\r\n");
            W(xrefPos.ToString(CultureInfo.InvariantCulture) + "\r\n%%EOF");

            writer.Flush();
            return ms.ToArray();
        }
    }
}
