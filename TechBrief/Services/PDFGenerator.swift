import UIKit
import PDFKit

// MARK: - PDF Generator

struct PDFGenerator {

    static func generate(from brief: Brief) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842) // A4
        let margin: CGFloat = 50
        let contentW = pageRect.width - margin * 2

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        return renderer.pdfData { ctx in
            ctx.beginPage()
            var y: CGFloat = margin

            // ── Colours ─────────────────────────────────────────────────────
            let navy   = UIColor(red: 0.102, green: 0.122, blue: 0.235, alpha: 1)
            let accent = UIColor(red: 0.145, green: 0.388, blue: 0.918, alpha: 1)
            let green  = UIColor(red: 0.063, green: 0.725, blue: 0.506, alpha: 1)
            let red    = UIColor(red: 0.937, green: 0.267, blue: 0.267, alpha: 1)
            let muted  = UIColor(red: 0.392, green: 0.455, blue: 0.545, alpha: 1)
            let light  = UIColor(red: 0.945, green: 0.957, blue: 0.973, alpha: 1)
            let codeBg = UIColor(red: 0.059, green: 0.090, blue: 0.165, alpha: 1)
            let codeFg = UIColor(red: 0.886, green: 0.910, blue: 0.941, alpha: 1)
            let bodyC  = UIColor(red: 0.200, green: 0.255, blue: 0.337, alpha: 1)

            // ── Helpers ──────────────────────────────────────────────────────
            func drawRect(_ rect: CGRect, color: UIColor, radius: CGFloat = 0) {
                color.setFill()
                UIBezierPath(roundedRect: rect, cornerRadius: radius).fill()
            }

            func para(_ text: String,
                      _ font: UIFont,
                      _ color: UIColor,
                      x: CGFloat = margin,
                      y: CGFloat,
                      width: CGFloat,
                      lineSpacing: CGFloat = 4) -> CGFloat {
                let style = NSMutableParagraphStyle()
                style.lineSpacing = lineSpacing
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font, .foregroundColor: color, .paragraphStyle: style
                ]
                let str = NSAttributedString(string: text, attributes: attrs)
                let textRect = CGRect(x: x, y: y, width: width, height: 2000)
                let drawn = str.boundingRect(with: textRect.size,
                                             options: [.usesLineFragmentOrigin, .usesFontLeading],
                                             context: nil)
                str.draw(in: CGRect(x: x, y: y, width: width, height: drawn.height + 2))
                return drawn.height + lineSpacing
            }

            @discardableResult
            func sectionHeader(_ label: String, _ title: String) -> CGFloat {
                let h1 = para(label, .systemFont(ofSize: 8, weight: .bold),
                              accent, y: y, width: contentW)
                y += h1 + 2
                let h2 = para(title, .systemFont(ofSize: 15, weight: .bold),
                              navy, y: y, width: contentW)
                y += h2 + 4
                accent.setStroke()
                let line = UIBezierPath()
                line.move(to: CGPoint(x: margin, y: y))
                line.addLine(to: CGPoint(x: margin + contentW, y: y))
                line.lineWidth = 1.5
                line.stroke()
                y += 8
                return 0
            }

            func newPageIfNeeded(needed: CGFloat) {
                if y + needed > pageRect.height - margin {
                    ctx.beginPage()
                    y = margin
                }
            }

            // ── HERO ─────────────────────────────────────────────────────────
            let heroH: CGFloat = 130
            drawRect(CGRect(x: margin, y: y, width: contentW, height: heroH),
                     color: navy, radius: 10)

            let heroY = y + 18
            _ = para("TECHBRIEF", .systemFont(ofSize: 9, weight: .bold),
                     accent, x: margin + 18, y: heroY, width: contentW - 36)
            _ = para(brief.topic, .systemFont(ofSize: 30, weight: .heavy),
                     .white, x: margin + 18, y: heroY + 16, width: contentW - 36)
            _ = para(brief.tagline, .systemFont(ofSize: 11, weight: .regular),
                     UIColor(white: 0.8, alpha: 1),
                     x: margin + 18, y: heroY + 58, width: contentW - 36)
            _ = para("5 min read  ·  Code example  ·  YouTube links",
                     .systemFont(ofSize: 8), UIColor(white: 1, alpha: 0.45),
                     x: margin + 18, y: heroY + 90, width: contentW - 36)

            y += heroH + 20

            // ── WHAT IS IT ───────────────────────────────────────────────────
            sectionHeader("01  WHAT IS IT?", "What is \(brief.topic)?")
            newPageIfNeeded(needed: 60)
            y += para(brief.whatIsIt, .systemFont(ofSize: 10.5), bodyC,
                      y: y, width: contentW, lineSpacing: 4)
            y += 14

            // ── WHY IT MATTERS ───────────────────────────────────────────────
            newPageIfNeeded(needed: 60)
            sectionHeader("02  WHY IT MATTERS", "Why It Matters")
            y += para(brief.whyItMatters, .systemFont(ofSize: 10.5), bodyC,
                      y: y, width: contentW, lineSpacing: 4)
            y += 14

            // ── KEY CONCEPTS ─────────────────────────────────────────────────
            newPageIfNeeded(needed: 80)
            sectionHeader("03  KEY CONCEPTS", "Key Concepts")
            for concept in brief.concepts {
                newPageIfNeeded(needed: 30)
                // bullet arrow
                let arrowAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 11, weight: .bold),
                    .foregroundColor: accent
                ]
                NSAttributedString(string: "▸ ", attributes: arrowAttrs)
                    .draw(at: CGPoint(x: margin, y: y))

                let termAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10.5, weight: .bold),
                    .foregroundColor: navy
                ]
                let defAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10.5),
                    .foregroundColor: bodyC
                ]
                let combined = NSMutableAttributedString()
                combined.append(NSAttributedString(string: concept.term, attributes: termAttrs))
                combined.append(NSAttributedString(string: "  —  \(concept.definition)", attributes: defAttrs))
                let textRect = CGRect(x: margin + 16, y: y,
                                      width: contentW - 16, height: 2000)
                let bounds = combined.boundingRect(with: textRect.size,
                                                   options: [.usesLineFragmentOrigin],
                                                   context: nil)
                combined.draw(in: CGRect(x: margin + 16, y: y,
                                         width: contentW - 16,
                                         height: bounds.height + 2))
                y += bounds.height + 6
            }
            y += 8

            // ── WHEN TO USE ──────────────────────────────────────────────────
            newPageIfNeeded(needed: 100)
            sectionHeader("04  WHEN TO USE IT", "When to Use It")

            let colW = (contentW - 8) / 2
            let headerH: CGFloat = 22

            // Use header
            drawRect(CGRect(x: margin, y: y, width: colW, height: headerH),
                     color: green, radius: 4)
            _ = para("✅  USE WHEN", .systemFont(ofSize: 8.5, weight: .bold),
                     .white, x: margin + 8, y: y + 5, width: colW - 16)

            // Avoid header
            drawRect(CGRect(x: margin + colW + 8, y: y, width: colW, height: headerH),
                     color: red, radius: 4)
            _ = para("⚠️  AVOID WHEN", .systemFont(ofSize: 8.5, weight: .bold),
                     .white, x: margin + colW + 16, y: y + 5, width: colW - 16)

            y += headerH
            let rowH: CGFloat = 22
            let maxRows = max(brief.useWhen.count, brief.avoidWhen.count)
            for i in 0..<maxRows {
                let ry = y + CGFloat(i) * rowH
                // use cell
                UIColor(red: 0.94, green: 0.99, blue: 0.96, alpha: 1).setFill()
                UIBezierPath(rect: CGRect(x: margin, y: ry, width: colW, height: rowH)).fill()
                if i < brief.useWhen.count {
                    _ = para("• \(brief.useWhen[i])", .systemFont(ofSize: 9), bodyC,
                             x: margin + 8, y: ry + 5, width: colW - 16)
                }
                // avoid cell
                UIColor(red: 1.0, green: 0.945, blue: 0.945, alpha: 1).setFill()
                UIBezierPath(rect: CGRect(x: margin + colW + 8, y: ry,
                                          width: colW, height: rowH)).fill()
                if i < brief.avoidWhen.count {
                    _ = para("• \(brief.avoidWhen[i])", .systemFont(ofSize: 9), bodyC,
                             x: margin + colW + 16, y: ry + 5, width: colW - 16)
                }
            }
            y += CGFloat(maxRows) * rowH + 14

            // ── CODE EXAMPLE ─────────────────────────────────────────────────
            newPageIfNeeded(needed: 120)
            sectionHeader("05  QUICK EXAMPLE", "Quick Example")
            y += para(brief.codeComment, .systemFont(ofSize: 10.5), bodyC,
                      y: y, width: contentW)
            y += 6

            let codeH = CGFloat(brief.codeLines.count) * 13 + 24
            drawRect(CGRect(x: margin, y: y, width: contentW, height: codeH),
                     color: codeBg, radius: 6)
            var codeY = y + 12
            for line in brief.codeLines {
                let isComment = line.trimmingCharacters(in: .whitespaces).hasPrefix("#")
                    || line.trimmingCharacters(in: .whitespaces).hasPrefix("//")
                _ = para(line.isEmpty ? " " : line,
                         UIFont(name: "Menlo", size: 8.5) ?? .monospacedSystemFont(ofSize: 8.5, weight: .regular),
                         isComment ? UIColor(white: 0.42, alpha: 1) : codeFg,
                         x: margin + 14, y: codeY, width: contentW - 28)
                codeY += 13
            }
            y += codeH + 14

            // ── YOUTUBE LINKS ────────────────────────────────────────────────
            newPageIfNeeded(needed: 60)
            sectionHeader("06  WATCH & LEARN", "Watch & Learn (Under 15 min)")
            for video in brief.youtubeLinks {
                newPageIfNeeded(needed: 56)
                let cardH: CGFloat = 52
                drawRect(CGRect(x: margin, y: y, width: contentW, height: cardH),
                         color: light, radius: 6)

                // Play circle
                accent.setFill()
                UIBezierPath(ovalIn: CGRect(x: margin + 12, y: y + 12, width: 28, height: 28)).fill()
                UIColor.white.setFill()
                let play = UIBezierPath()
                play.move(to:    CGPoint(x: margin + 20, y: y + 18))
                play.addLine(to: CGPoint(x: margin + 20, y: y + 34))
                play.addLine(to: CGPoint(x: margin + 33, y: y + 26))
                play.close()
                play.fill()

                _ = para(video.title, .systemFont(ofSize: 10, weight: .semibold),
                         navy, x: margin + 50, y: y + 8, width: contentW - 58)
                _ = para("\(video.channel)  ·  \(video.duration)  ·  \(video.url)",
                         .systemFont(ofSize: 8.5), muted,
                         x: margin + 50, y: y + 28, width: contentW - 58)
                y += cardH + 6
            }
            y += 8

            // ── LEARN NEXT ───────────────────────────────────────────────────
            newPageIfNeeded(needed: 80)
            sectionHeader("07  WHAT'S NEXT", "What to Learn Next")
            for next in brief.learnNext {
                newPageIfNeeded(needed: 40)
                let arrowAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12, weight: .bold),
                    .foregroundColor: accent
                ]
                NSAttributedString(string: "→  \(next.topic)", attributes: arrowAttrs)
                    .draw(at: CGPoint(x: margin, y: y))
                y += 18
                y += para(next.description, .systemFont(ofSize: 10.5), bodyC,
                          y: y, width: contentW, lineSpacing: 3)
                y += 10
            }

            // ── FOOTER ───────────────────────────────────────────────────────
            let footerY = pageRect.height - margin + 6
            muted.setStroke()
            let footerLine = UIBezierPath()
            footerLine.move(to:    CGPoint(x: margin, y: footerY - 6))
            footerLine.addLine(to: CGPoint(x: margin + contentW, y: footerY - 6))
            footerLine.lineWidth = 0.5
            footerLine.stroke()

            let df = DateFormatter()
            df.dateFormat = "MMMM yyyy"
            _ = para("TechBrief  ·  On-demand tech cheat sheets  ·  \(df.string(from: Date()))",
                     .systemFont(ofSize: 8), muted,
                     x: margin, y: footerY, width: contentW)
        }
    }
}
