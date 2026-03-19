interface ProcessedLine {
  type: 'line' | 'code' | 'table';
  content: string;
}

interface TableData {
  rows: string[][];
  alignments: string[];
}

@Component
export struct MarkdownText {
  @Prop markdown: string = '';
  @Prop textColor: string = '#333333';
  @Prop fontSize: number = 15;
  
  private processedLines: ProcessedLine[] = [];
  
  build() {
    Column() {
      this.renderMarkdown(this.markdown)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .constraintSize({ minWidth: 50 })
  }
  
  aboutToAppear() {
    this.processedLines = this.processMarkdown(this.markdown);
  }
  
  private processMarkdown(text: string): ProcessedLine[] {
    const lines = text.split('\n');
    const result: ProcessedLine[] = [];
    let inCodeBlock = false;
    let codeBlockContent = '';
    let inTable = false;
    let tableContent = '';
    
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      
      if (line.startsWith('```')) {
        if (inCodeBlock) {
          result.push({ type: 'code', content: codeBlockContent.trim() });
          codeBlockContent = '';
          inCodeBlock = false;
        } else {
          inCodeBlock = true;
        }
      } else if (inCodeBlock) {
        codeBlockContent += line + '\n';
      } else if (line.trim().startsWith('|') && line.trim().endsWith('|')) {
        if (!inTable) {
          inTable = true;
          tableContent = line + '\n';
        } else {
          tableContent += line + '\n';
        }
      } else if (inTable && line.trim().match(/^\|[\s\-:]+\|$/)) {
        tableContent += line + '\n';
      } else {
        if (inTable) {
          result.push({ type: 'table', content: tableContent.trim() });
          tableContent = '';
          inTable = false;
        }
        result.push({ type: 'line', content: line });
      }
    }
    
    if (inTable && tableContent.trim().length > 0) {
      result.push({ type: 'table', content: tableContent.trim() });
    }
    
    return result;
  }
  
  @Builder
  renderMarkdown(text: string) {
    if (!text || text.length === 0) {
      Text('')
        .fontSize(this.fontSize)
        .fontColor(this.textColor)
    } else {
      ForEach(this.processedLines, (processedLine: ProcessedLine, index: number) => {
        if (processedLine.type === 'code') {
          this.renderCodeBlock(processedLine.content)
        } else if (processedLine.type === 'table') {
          this.renderTable(processedLine.content)
        } else {
          this.renderLine(processedLine.content, index)
        }
      }, (processedLine: ProcessedLine, index: number) => `${index}_${processedLine.content.length}_${processedLine.type}`)
    }
  }
  
  @Builder
  renderLine(line: string, index: number) {
    if (line.startsWith('###### ')) {
      Text(line.substring(7))
        .fontSize(this.fontSize)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textColor)
        .margin({ top: 8, bottom: 2 })
        .width('100%')
    } else if (line.startsWith('##### ')) {
      Text(line.substring(6))
        .fontSize(this.fontSize + 1)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textColor)
        .margin({ top: 10, bottom: 3 })
        .width('100%')
    } else if (line.startsWith('#### ')) {
      Text(line.substring(5))
        .fontSize(this.fontSize + 2)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textColor)
        .margin({ top: 12, bottom: 4 })
        .width('100%')
    } else if (line.startsWith('### ')) {
      Text(line.substring(4))
        .fontSize(this.fontSize + 4)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textColor)
        .margin({ top: 12, bottom: 4 })
        .width('100%')
    } else if (line.startsWith('## ')) {
      Text(line.substring(3))
        .fontSize(this.fontSize + 6)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textColor)
        .margin({ top: 16, bottom: 6 })
        .width('100%')
    } else if (line.startsWith('# ')) {
      Text(line.substring(2))
        .fontSize(this.fontSize + 8)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textColor)
        .margin({ top: 20, bottom: 8 })
        .width('100%')
    } else if (line.match(/^-\s+\[x\]\s/)) {
      Row() {
        Text('☑ ')
          .fontSize(this.fontSize)
          .fontColor('#4CAF50')
        Text(this.renderInlineMarkdown(line.substring(6)))
          .fontSize(this.fontSize)
          .fontColor(this.textColor)
          .layoutWeight(1)
      }
      .width('100%')
      .margin({ top: 2, bottom: 2 })
      .padding({ left: 8 })
    } else if (line.match(/^-\s+\[\s\]\s/)) {
      Row() {
        Text('☐ ')
          .fontSize(this.fontSize)
          .fontColor('#9E9E9E')
        Text(this.renderInlineMarkdown(line.substring(6)))
          .fontSize(this.fontSize)
          .fontColor(this.textColor)
          .layoutWeight(1)
      }
      .width('100%')
      .margin({ top: 2, bottom: 2 })
      .padding({ left: 8 })
    } else if (line.startsWith('- ') || line.startsWith('* ')) {
      Row() {
        Text('• ')
          .fontSize(this.fontSize)
          .fontColor(this.textColor)
        Text(this.renderInlineMarkdown(line.substring(2)))
          .fontSize(this.fontSize)
          .fontColor(this.textColor)
          .layoutWeight(1)
      }
      .width('100%')
      .margin({ top: 2, bottom: 2 })
      .padding({ left: 8 })
    } else if (line.match(/^\d+\.\s/)) {
      Row() {
        Text(line.substring(0, line.indexOf('. ') + 2))
          .fontSize(this.fontSize)
          .fontColor(this.textColor)
        Text(this.renderInlineMarkdown(line.substring(line.indexOf('. ') + 2)))
          .fontSize(this.fontSize)
          .fontColor(this.textColor)
          .layoutWeight(1)
      }
      .width('100%')
      .margin({ top: 2, bottom: 2 })
      .padding({ left: 8 })
    } else if (line.startsWith('> ')) {
      Row() {
        Column()
          .width(3)
          .height('100%')
          .backgroundColor('#2196F3')
          .margin({ right: 8 })
        
        Text(this.renderInlineMarkdown(line.substring(2)))
          .fontSize(this.fontSize)
          .fontColor(this.textColor)
          .fontStyle(FontStyle.Italic)
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 8, top: 4, bottom: 4, right: 8 })
      .backgroundColor('#F5F5F5')
      .borderRadius(4)
      .margin({ top: 4, bottom: 4 })
    } else if (line.startsWith('---') || line.startsWith('***') || line.startsWith('___')) {
      Divider()
        .color('#E0E0E0')
        .margin({ top: 8, bottom: 8 })
    } else if (line.trim().length === 0) {
      Text('')
        .height(8)
        .width('100%')
    } else {
      Text(this.renderInlineMarkdown(line))
        .fontSize(this.fontSize)
        .fontColor(this.textColor)
        .lineHeight(22)
        .margin({ top: 2, bottom: 2 })
        .width('100%')
    }
  }
  
  private renderInlineMarkdown(text: string): string {
    let result = text;
    
    const htmlTagPlaceholders: Map<string, string> = new Map();
    let placeholderIndex = 0;
    
    result = result.replace(/<\/?[a-zA-Z][a-zA-Z0-9]*(\s[^>]*)?\/?>/g, (match) => {
      const placeholder = `__HTML_TAG_${placeholderIndex}__`;
      htmlTagPlaceholders.set(placeholder, match);
      placeholderIndex++;
      return placeholder;
    });
    
    result = result.replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2" style="color:#1976D2;text-decoration:underline;">$1</a>');
    result = result.replace(/!\[([^\]]*)\]\(([^)]+)\)/g, '📷[$1]');
    result = result.replace(/~~(.+?)~~/g, '<s>$1</s>');
    result = result.replace(/\*\*\*(.+?)\*\*\*/g, '<b><i>$1</i></b>');
    result = result.replace(/\*\*(.+?)\*\*/g, '<b>$1</b>');
    result = result.replace(/\*(.+?)\*/g, '<i>$1</i>');
    result = result.replace(/__(.+?)__/g, '<b>$1</b>');
    result = result.replace(/_(.+?)_/g, '<i>$1</i>');
    result = result.replace(/`(.+?)`/g, '<font color="#D32F2F" face="monospace" style="background-color:#F5F5F5;padding:2px 4px;border-radius:3px;">$1</font>');
    result = result.replace(/==(.+?)==/g, '<font style="background-color:#FFEB3B;">$1</font>');
    
    htmlTagPlaceholders.forEach((value, key) => {
      result = result.replace(key, value);
    });
    
    return result;
  }
  
  @Builder
  renderCodeBlock(code: string) {
    Column() {
      Text(code.trim())
        .fontSize(this.fontSize - 2)
        .fontColor('#D4D4D4')
        .backgroundColor('#1E1E1E')
        .padding(12)
        .borderRadius(8)
        .width('100%')
        .fontFamily('monospace')
    }
    .width('100%')
    .margin({ top: 8, bottom: 8 })
  }
  
  @Builder
  renderTable(tableMarkdown: string) {
    Column() {
      ForEach(this.parseTable(tableMarkdown).rows, (row: string[], rowIndex: number) => {
        Row() {
          ForEach(row, (cell: string, cellIndex: number) => {
            Text(this.renderInlineMarkdown(cell))
              .fontSize(this.fontSize - 1)
              .fontColor(this.textColor)
              .padding(8)
              .backgroundColor(rowIndex === 0 ? '#E3F2FD' : (rowIndex % 2 === 0 ? '#FAFAFA' : '#FFFFFF'))
              .fontWeight(rowIndex === 0 ? FontWeight.Bold : FontWeight.Normal)
              .textAlign(this.parseTable(tableMarkdown).alignments[cellIndex] === 'center' ? TextAlign.Center : 
                        this.parseTable(tableMarkdown).alignments[cellIndex] === 'right' ? TextAlign.End : TextAlign.Start)
              .layoutWeight(1)
              .border({ width: 0.5, color: '#E0E0E0' })
          }, (cell: string, cellIndex: number) => `${rowIndex}_${cellIndex}_${cell}`)
        }
        .width('100%')
      }, (row: string[], rowIndex: number) => `${rowIndex}_${row.length}`)
    }
    .width('100%')
    .margin({ top: 8, bottom: 8 })
    .borderRadius(4)
    .border({ width: 1, color: '#E0E0E0' })
    .clip(true)
  }
  
  private parseTable(tableMarkdown: string): TableData {
    const lines = tableMarkdown.split('\n');
    const rows: string[][] = [];
    let alignments: string[] = [];
    
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i].trim();
      if (line.match(/^\|[\s\-:]+\|$/)) {
        const cells = line.split('|').filter(c => c.trim().length > 0);
        alignments = cells.map(cell => {
          const trimmed = cell.trim();
          if (trimmed.startsWith(':') && trimmed.endsWith(':')) return 'center';
          if (trimmed.endsWith(':')) return 'right';
          return 'left';
        });
      } else {
        const cells = line.split('|').filter(c => c.trim().length > 0);
        if (cells.length > 0) {
          rows.push(cells.map(c => c.trim()));
        }
      }
    }
    
    return { rows, alignments };
  }
}

