import clsx from 'clsx';
import Heading from '@theme/Heading';
import styles from './styles.module.css';

const FeatureList = [
  {
    title: 'Lightweight & Modular',
    description: (
      <>
        Simple, reusable utilities that focus on specific AWS tasks without unnecessary complexity.
        Each tool is designed to do one thing well.
      </>
    ),
  },
  {
    title: 'Automation First',
    description: (
      <>
        Reduce repetitive AWS workflows and manual tasks. Perfect for DevOps teams
        looking to streamline their cloud operations.
      </>
    ),
  },
  {
    title: 'Production Ready',
    description: (
      <>
        Battle-tested utilities suitable for learning, experimentation, and real-world
        production environments with proper error handling.
      </>
    ),
  },
];

function Feature({Svg, title, description}) {
  return (
    <div className={clsx('col col--4')}>
      <div className="text--center padding-horiz--md">
        <Heading as="h3">{title}</Heading>
        <p>{description}</p>
      </div>
    </div>
  );
}

export default function HomepageFeatures() {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row">
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}
